-- 在数据库存储的代码(过程/函数/包/触发器)里查找硬编码的 schema 前缀引用。
-- 和 check_hardcoded_schema_refs.sh(查应用代码)互为补充 -- ALL_DEPENDENCIES
-- 只记录 Oracle 编译期解析出的引用,所以这里用文本搜索,能额外抓到
-- ALL_DEPENDENCIES 抓不到的动态 SQL(EXECUTE IMMEDIATE 里运行时拼出来的
-- 带 schema 前缀的字符串)。
-- Search DB-stored code (procedures/functions/packages/triggers) for
-- hardcoded schema-qualified references. Complements the app-code grep
-- in check_hardcoded_schema_refs.sh -- ALL_DEPENDENCIES only tracks
-- references Oracle's parser resolved at compile time, so this text
-- search also catches dynamic SQL (EXECUTE IMMEDIATE with a
-- schema-qualified string built at runtime) that ALL_DEPENDENCIES
-- would miss.

-- PL/SQL 源码:存储过程、函数、包、包体、触发器
-- PL/SQL source: procedures, functions, packages, package bodies, triggers
SELECT owner, name, type, line, text
FROM all_source
WHERE UPPER(text) LIKE '%SALESYS.%' OR UPPER(text) LIKE '%SALESYSFLOW.%'
ORDER BY owner, name, line;

-- 视图(ALL_SOURCE 不包含视图定义,需要单独查 ALL_VIEWS)
-- Views (ALL_SOURCE does not include view definitions, check separately)
--
-- 注意:ALL_VIEWS.TEXT 是 LONG 类型,Oracle 不允许对 LONG 列直接用
-- UPPER() 这类函数(会报 ORA-00932: inconsistent datatypes),所以
-- 这里不包 UPPER(),直接用 LIKE 分别匹配大小写变体(LIKE 本身可以
-- 直接作用在 LONG 列上)。
-- Note: ALL_VIEWS.TEXT is a LONG column -- Oracle does not allow
-- applying a function like UPPER() directly to a LONG column (raises
-- ORA-00932: inconsistent datatypes), so this skips UPPER() and
-- matches case variants directly with LIKE instead (LIKE itself can
-- be applied to a LONG column).
SELECT owner, view_name, text
FROM all_views
WHERE text LIKE '%SALESYS.%' OR text LIKE '%salesys.%'
   OR text LIKE '%SALESYSFLOW.%' OR text LIKE '%salesysflow.%';
