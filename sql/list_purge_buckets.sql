SELECT 
    id AS bucket_id,
    name AS bucket_name
FROM 
    container.user_bucket
WHERE 
    name LIKE 'Purge Eligible - %'
ORDER BY 
    name;