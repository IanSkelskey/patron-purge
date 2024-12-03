DO $$
DECLARE
    bucket RECORD;
BEGIN
    -- Cursor to retrieve buckets created for purge-eligible patrons
    FOR bucket IN
        SELECT id, name
        FROM container.user_bucket
        WHERE name LIKE 'Purge Eligible - %'
    LOOP
        -- Delete users associated with the current bucket
        FOR user_record IN
            SELECT target_user AS user_id
            FROM container.user_bucket_item
            WHERE bucket = bucket.id
        LOOP
            BEGIN
                -- Call the usr_delete function for each user ID
                PERFORM actor.usr_delete(user_record.user_id, 1);
                RAISE NOTICE 'Deleted user with ID % from bucket %', user_record.user_id, bucket.name;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Failed to delete user with ID % from bucket %: %', user_record.user_id, bucket.name, SQLERRM;
            END;
        END LOOP;

        -- Delete bucket items
        BEGIN
            DELETE FROM container.user_bucket_item
            WHERE bucket = bucket.id;
            RAISE NOTICE 'Deleted items from bucket %', bucket.name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Failed to delete items from bucket %: %', bucket.name, SQLERRM;
        END;

        -- Delete the bucket
        BEGIN
            DELETE FROM container.user_bucket
            WHERE id = bucket.id;
            RAISE NOTICE 'Deleted bucket %', bucket.name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Failed to delete bucket %: %', bucket.name, SQLERRM;
        END;
    END LOOP;
END $$;
