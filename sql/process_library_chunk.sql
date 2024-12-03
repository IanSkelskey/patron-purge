DO $$
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
END $$;
