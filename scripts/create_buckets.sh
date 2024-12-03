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
DB_NAME="$1"
SQL_FILE="../sql/process_library_chunk.sql"
PARALLEL_PROCESSES=5
CHUNK_SIZE=6
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
        psql -d "$DB_NAME" -v library_id="$LIBRARY_ID" -f "$SQL_FILE"
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
