# Patron Purge

This repository contains scripts for purging patron records from an Evergreen ILS database. The scripts are designed to be run on an Evergreen database server and are written in SQL and shell script.

## Purge Criteria

A patron record is eligible for purging if it meets the following criteria:

- No activity in the last 5 years
- No lost items
- No bills

## Purge Process

The purge process consists of the following steps:

1. **Identify Eligible Patrons**: Run the `find_purge_eligible_patrons_and_write_inserts.sql` script to generate insert statements for creating purge buckets. If using PGAdmin, open a query tool, paste the script contents, and save the results to a file. Remove double quotes from the file, copy its contents to a new query tool window, and run the script to create the purge buckets.

2. **Review by Libraries**: Provide libraries access to the purge buckets and allow them time to review the patrons. Libraries can exclude patrons from the purge by removing their records from the purge bucket.

3. **Purge Patrons**: After the review period, run the `purge_from_buckets.sql` script to delete the patrons from the database.