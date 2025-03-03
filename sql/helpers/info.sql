SELECT 
    routine_name
FROM 
    information_schema.routines
WHERE 
    routine_schema = 'actor'
    AND routine_type = 'FUNCTION'
ORDER BY 
    routine_name;

-- Query to get the implementation of actor.usr_delete
SELECT 
    pg_get_functiondef(p.oid) AS function_definition
FROM 
    pg_proc p
JOIN 
    pg_namespace n ON p.pronamespace = n.oid
WHERE 
    n.nspname = 'actor'
    AND p.proname = 'usr_delete';

-- Query to get the implementation of actor.usr_purge_data
SELECT 
    pg_get_functiondef(p.oid) AS function_definition
FROM 
    pg_proc p
JOIN 
    pg_namespace n ON p.pronamespace = n.oid
WHERE 
    n.nspname = 'actor'
    AND p.proname = 'usr_purge_data';

-- Query to get all purge-eligible patrons
WITH per_library AS ( -- per_library is a CTE that provides the library_id, shortname
    SELECT o.id AS library_id,
           o.shortname,
           CASE WHEN o.shortname = 'ROCKVL' THEN '8 years'::interval ELSE '5 years'::interval END AS purge_limit
    FROM actor.org_unit o
),
purge_eligible_raw AS ( -- purge_eligible_raw is a CTE that provides the patron_id, home_ou, shortname, user_purge_limit
    SELECT u.id AS patron_id,
           u.home_ou,
           o.shortname,
           CASE WHEN o.shortname = 'ROCKVL' THEN '8 years'::interval ELSE '5 years'::interval END AS user_purge_limit
    FROM actor.usr u
    JOIN permission.grp_tree g ON u.profile = g.id
    JOIN actor.org_unit o ON u.home_ou = o.id
    WHERE u.deleted = TRUE
      AND u.usrname NOT LIKE '%PURGED%'
      AND u.first_given_name NOT LIKE '%PURGED%'
      AND u.family_name NOT LIKE '%PURGED%'
      AND g.parent = 2
),
purge_eligible AS ( -- purge_eligible is a CTE that provides the patron_id, home_ou, user_purge_limit
    SELECT r.patron_id, r.home_ou, r.user_purge_limit
    FROM purge_eligible_raw r
    WHERE NOT EXISTS ( -- Check for lost items
        SELECT 1
        FROM asset.copy c
        JOIN action.all_circulation ac ON ac.target_copy = c.id
        WHERE ac.usr = r.patron_id
          AND c.status = 3
    )
    AND NOT EXISTS ( -- Check for circulations within the user_purge_limit
        SELECT 1
        FROM action.all_circulation ac
        WHERE ac.usr = r.patron_id
          AND ac.xact_finish > (NOW() - r.user_purge_limit)
    )
    AND NOT EXISTS ( -- Check for hold requests within the user_purge_limit
        SELECT 1
        FROM action.hold_request hr
        WHERE hr.usr = r.patron_id
          AND hr.request_time > (NOW() - r.user_purge_limit)
    )
    AND NOT EXISTS ( -- Check for billable transactions
        SELECT 1
        FROM money.billable_xact bx
        WHERE bx.usr = r.patron_id
          AND bx.xact_finish IS NULL
    )
)
-- Select all purge-eligible patrons
SELECT 
    p.patron_id,
    p.home_ou,
    pl.shortname,
    p.user_purge_limit
FROM purge_eligible p
JOIN per_library pl ON p.home_ou = pl.library_id;

-- ERROR:  update or delete on table "usr_address" violates foreign key constraint "actor_usr_billining_address_fkey" on table "usr"
-- DETAIL:  Key (id)=(44480) is still referenced from table "usr".
-- SQL state: 23503

-- The destination user is set to 1 in the actor.usr_delete function because it is a common practice to use a default administrative user (often with ID 1) as a placeholder for various ownership or reference fields when purging or anonymizing user data. This ensures that any foreign key constraints or references to the purged user are maintained by pointing them to a generic administrative user.
-- 
-- However, if you have a specific user ID that should be used as the destination user, you can modify the function call to use that ID instead of 1.


BEGIN;

DO $$
BEGIN
    -- Call the usr_delete function for the specified user ID
    PERFORM actor.usr_delete(44480, 1);
    RAISE NOTICE 'Deleted user with ID 44480';
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Failed to delete user with ID 44480: %', SQLERRM;
END;
$$;

ROLLBACK;
COMMIT; -- Uncomment this line to commit the transaction if the test is successful