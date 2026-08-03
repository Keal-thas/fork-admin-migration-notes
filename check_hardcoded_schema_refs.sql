-- Search DB-stored code (procedures/functions/packages/triggers) for
-- hardcoded schema-qualified references. Complements the app-code grep
-- in check_hardcoded_schema_refs.sh -- ALL_DEPENDENCIES only tracks
-- references Oracle's parser resolved at compile time, so this text
-- search also catches dynamic SQL (EXECUTE IMMEDIATE with a
-- schema-qualified string built at runtime) that ALL_DEPENDENCIES
-- would miss.

-- PL/SQL source: procedures, functions, packages, package bodies, triggers
SELECT owner, name, type, line, text
FROM all_source
WHERE UPPER(text) LIKE '%SALESYS.%' OR UPPER(text) LIKE '%SALESYSFLOW.%'
ORDER BY owner, name, line;

-- Views (ALL_SOURCE does not include view definitions, check separately)
SELECT owner, view_name, text
FROM all_views
WHERE UPPER(text) LIKE '%SALESYS.%' OR UPPER(text) LIKE '%SALESYSFLOW.%';
