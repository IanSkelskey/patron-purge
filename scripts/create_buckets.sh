#!/bin/bash

# Create Purge Eligible Buckets
# This script creates user buckets for purge-eligible patrons in each library.
# The script fetches library IDs from the database, splits them into chunks,
# and processes each chunk in parallel to create user buckets for purge-eligible patrons.
# The script logs the progress of each library to a file named completed_libraries.log.

# Check if the database name is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <database_name>"
    exit 1
fi

# Configuration
DB_NAME="$1"                   # Database name from the command-line argument
PARALLEL_PROCESSES=5           # Number of parallel processes
CHUNK_SIZE=6                  # Number of libraries per chunk
LIBRARY_ID_FILE="library_ids.txt"
COMPLETED_LOG="completed_libraries.log"

# Step 1: Fetch library IDs
echo "Fetching library IDs..."
psql -d "$DB_NAME" -t -A -c "SELECT id FROM actor.org_unit ORDER BY id;" > "$LIBRARY_ID_FILE"
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch library IDs."
    exit 1
fi

# Step 2: Split library IDs into chunks
echo "Splitting library IDs into chunks..."
split -l "$CHUNK_SIZE" "$LIBRARY_ID_FILE" library_chunk_
if [ $? -ne 0 ]; then
    echo "Error: Failed to split library IDs."
    exit 1
fi

# Step 3: Define the library processing function
process_library_chunk() {
    local LIBRARY_FILE=$1

    while read -r LIBRARY_ID; do
        echo "Processing library ID: $LIBRARY_ID"
        psql -d "$DB_NAME" -v library_id="$LIBRARY_ID" <<EOF
        DO \$\$
        DECLARE
            bucket_id INTEGER;
            purge_limit INTERVAL;
        BEGIN
            -- Determine the purge limit based on the library
            IF (SELECT shortname FROM actor.org_unit WHERE id = :library_id) = 'ROCKVL' THEN
                purge_limit := INTERVAL '8 years';
            ELSE
                purge_limit := INTERVAL '5 years';
            END IF;

            -- Create temporary tables for precomputing data
            CREATE TEMP TABLE temp_deleted_patrons AS
            SELECT u.id
            FROM actor.usr u
            JOIN permission.grp_tree g ON u.profile = g.id
            WHERE u.deleted = TRUE
              AND u.usrname NOT LIKE '%PURGED%'
              AND u.first_given_name NOT LIKE '%PURGED%'
              AND u.family_name NOT LIKE '%PURGED%'
              AND g.parent = 2;

            CREATE TEMP TABLE temp_eligible_patrons AS
            SELECT u.id
            FROM actor.usr u
            WHERE NOT EXISTS (
                SELECT 1
                FROM asset.copy c
                JOIN action.all_circulation ac ON ac.target_copy = c.id
                WHERE ac.usr = u.id AND c.status = 3
            )
            AND NOT EXISTS (
                SELECT 1
                FROM action.all_circulation ac
                WHERE ac.usr = u.id AND ac.xact_finish > (NOW() - purge_limit)
            )
            AND NOT EXISTS (
                SELECT 1
                FROM action.hold_request hr
                WHERE hr.usr = u.id AND hr.request_time > (NOW() - purge_limit)
            )
            AND NOT EXISTS (
                SELECT 1
                FROM money.billable_xact bx
                WHERE bx.usr = u.id AND bx.xact_finish IS NULL
            );

            -- Create a user bucket for the current library
            INSERT INTO container.user_bucket (owning_lib, owner, name)
            VALUES (:library_id, :library_id, CONCAT('Purge Eligible - ', (SELECT shortname FROM actor.org_unit WHERE id = :library_id)))
            RETURNING id INTO bucket_id;

            -- Add purge-eligible patrons to the bucket
            INSERT INTO container.user_bucket_item (bucket, target_user)
            SELECT bucket_id, dp.id
            FROM temp_deleted_patrons dp
            JOIN temp_eligible_patrons ep ON dp.id = ep.id;

            -- Drop temporary tables for cleanup
            DROP TABLE IF EXISTS temp_deleted_patrons;
            DROP TABLE IF EXISTS temp_eligible_patrons;

            -- Log progress
            RAISE NOTICE 'Completed library with ID %', :library_id;
        END \$\$;
EOF

        if [ $? -eq 0 ]; then
            echo "Library ID $LIBRARY_ID processed successfully." >> "$COMPLETED_LOG"
        else
            echo "Error processing library ID $LIBRARY_ID."
        fi
    done < "$LIBRARY_FILE"
}

# Step 4: Run the processing in parallel
echo "Processing library chunks in parallel..."
find . -name "library_chunk_*" | xargs -n 1 -P "$PARALLEL_PROCESSES" -I {} bash -c "process_library_chunk {}"

# Step 5: Cleanup
echo "Cleaning up temporary files..."
rm -f library_chunk_*
rm -f "$LIBRARY_ID_FILE"

echo "Processing complete! Check $COMPLETED_LOG for details."
