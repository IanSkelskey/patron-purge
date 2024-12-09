-- Purpose: List all buckets that are eligible for purging.
SELECT 
    id AS bucket_id,
    name AS bucket_name
FROM 
    container.user_bucket
WHERE 
    name LIKE 'Purge Eligible - %'
ORDER BY 
    name;

-- Get bucket items for a specific bucket
SELECT
    b.id AS bucket_id,
    b.name AS bucket_name,
    ubit.target_user AS user_id
FROM container.user_bucket b
JOIN container.user_bucket_item ubit ON b.id = ubit.bucket
WHERE b.id = 692
ORDER BY ubit.target_user;

-- Count all users in all purge buckets
SELECT 
    COUNT(DISTINCT ubit.target_user) AS total_users
FROM 
    container.user_bucket b
JOIN 
    container.user_bucket_item ubit ON b.id = ubit.bucket
WHERE 
    b.name LIKE 'Purge Eligible - %';