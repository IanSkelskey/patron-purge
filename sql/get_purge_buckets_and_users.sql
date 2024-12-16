-- Purpose: List all buckets that are eligible for purging.
SELECT 
	aou.name AS "Library Name",
    cub.id AS "Bucket ID"
FROM 
    container.user_bucket AS cub
JOIN
	actor.org_unit AS aou
ON
	aou.id = cub.owning_lib
WHERE 
    cub.name LIKE 'Purge Eligible - %'
ORDER BY 
    aou.name;

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