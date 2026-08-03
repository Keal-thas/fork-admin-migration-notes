-- Cross-schema foreign keys
SELECT a.owner AS fk_owner, a.table_name AS fk_table, a.constraint_name,
       c.owner AS ref_owner, c.table_name AS ref_table
FROM all_constraints a
JOIN all_constraints c
  ON a.r_constraint_name = c.constraint_name AND a.r_owner = c.owner
WHERE a.constraint_type = 'R'
  AND a.owner IN ('SCHEMA1', 'SCHEMA2')
  AND c.owner IN ('SCHEMA1', 'SCHEMA2')
  AND a.owner != c.owner;

-- Cross-schema synonyms (including PUBLIC synonyms pointing at either schema)
SELECT owner, synonym_name, table_owner, table_name
FROM all_synonyms
WHERE table_owner IN ('SCHEMA1', 'SCHEMA2')
  AND (owner IN ('SCHEMA1', 'SCHEMA2') AND owner != table_owner
       OR owner = 'PUBLIC');

-- Broadest check: any object (view/procedure/trigger/package/etc.) in one
-- schema referencing an object owned by the other schema
SELECT owner, name, type AS referencing_type,
       referenced_owner, referenced_name, referenced_type
FROM all_dependencies
WHERE owner IN ('SCHEMA1', 'SCHEMA2')
  AND referenced_owner IN ('SCHEMA1', 'SCHEMA2')
  AND owner != referenced_owner;
