BEGIN;
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

-- Now join per_library and purge_eligible as needed
SELECT 
    'INSERT INTO container.user_bucket (owning_lib, owner, name) ' ||
    'VALUES ('||pl.library_id||', 1916108, '||quote_literal('Purge Eligible - '||pl.shortname)||') RETURNING id;' AS create_bucket_statement,
    string_agg(
        'INSERT INTO container.user_bucket_item (bucket, target_user) ' ||
        'VALUES ((SELECT id FROM container.user_bucket ' ||
                 'WHERE owning_lib = '||pl.library_id||' ' ||
                 'AND name = '||quote_literal('Purge Eligible - '||pl.shortname)||'), ' ||
        p.patron_id||');',
        E'\n'
    ) AS insert_user_statements
FROM per_library pl
JOIN purge_eligible p ON p.home_ou = pl.library_id
GROUP BY pl.library_id, pl.shortname;
ROLLBACK;
COMMIT;