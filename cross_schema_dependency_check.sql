-- 跨 schema 外键
-- Cross-schema foreign keys
SELECT a.owner AS fk_owner, a.table_name AS fk_table, a.constraint_name,
       c.owner AS ref_owner, c.table_name AS ref_table
FROM all_constraints a
JOIN all_constraints c
  ON a.r_constraint_name = c.constraint_name AND a.r_owner = c.owner
WHERE a.constraint_type = 'R'
  AND a.owner IN ('SALESYS', 'SALESYSFLOW')
  AND c.owner IN ('SALESYS', 'SALESYSFLOW')
  AND a.owner != c.owner;

-- 跨 schema 同义词(包括指向这两个 schema 的 PUBLIC 同义词)
-- Cross-schema synonyms (including PUBLIC synonyms pointing at either schema)
SELECT owner, synonym_name, table_owner, table_name
FROM all_synonyms
WHERE table_owner IN ('SALESYS', 'SALESYSFLOW')
  AND (owner IN ('SALESYS', 'SALESYSFLOW') AND owner != table_owner
       OR owner = 'PUBLIC');

-- 范围最广的检查:一个 schema 里的任意对象(视图/存储过程/触发器/包等)
-- 引用了另一个 schema 拥有的对象
-- Broadest check: any object (view/procedure/trigger/package/etc.) in one
-- schema referencing an object owned by the other schema
SELECT owner, name, type AS referencing_type,
       referenced_owner, referenced_name, referenced_type
FROM all_dependencies
WHERE owner IN ('SALESYS', 'SALESYSFLOW')
  AND referenced_owner IN ('SALESYS', 'SALESYSFLOW')
  AND owner != referenced_owner;
