WITH delete_user_statements AS (
    SELECT 
        'SELECT actor.usr_delete(' || ubi.target_user || ', 1);' AS delete_user_statements
    FROM container.user_bucket b
    JOIN container.user_bucket_item ubi ON b.id = ubi.bucket
    WHERE b.name LIKE 'Purge Eligible - %'
    AND NOT EXISTS (
        SELECT 1
        FROM actor.usr u
        JOIN actor.usr u2 ON u2.id = ubi.target_user
        WHERE (u.mailing_address = u2.mailing_address OR u.billing_address = u2.billing_address OR u.mailing_address = u2.billing_address OR u.billing_address = u2.mailing_address)
        AND u.id != ubi.target_user
    )
)
SELECT * FROM delete_user_statements;

-- Generate SQL statements to delete buckets

WITH delete_bucket_statements AS (
    SELECT
        'DELETE FROM container.user_bucket WHERE id = ' || b.id || ';' AS delete_bucket_statements
    FROM container.user_bucket b
    WHERE b.name LIKE 'Purge Eligible - %'
)
SELECT * FROM delete_bucket_statements;