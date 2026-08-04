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
-- 注意:ALL_VIEWS.TEXT 是 LONG 类型,LONG 列不能出现在 WHERE 子句里
-- (裸 LIKE 也不行,不只是函数的问题)。这里用 Oracle 自带的 TO_LOB()
-- 做类型转换,把 LONG 转成 CLOB 存进一张临时表 -- TO_LOB() 只能用在
-- INSERT ... SELECT 里,不能直接写在普通 SELECT 的 WHERE 里,所以要
-- 先转存。转成 CLOB 之后,WHERE/UPPER()/LIKE 就都能正常用了。
-- Note: ALL_VIEWS.TEXT is a LONG column, and LONG columns can't appear
-- in a WHERE clause at all (a bare LIKE fails too, not just a
-- function). This uses Oracle's built-in TO_LOB() to convert LONG to
-- CLOB into a scratch table -- TO_LOB() only works inside an
-- INSERT ... SELECT, not directly in a plain SELECT's WHERE, so it
-- has to land in a table first. Once it's a CLOB, WHERE/UPPER()/LIKE
-- all work normally.

CREATE TABLE tmp_view_text_check (
  owner     VARCHAR2(128),
  view_name VARCHAR2(128),
  view_text CLOB
);

INSERT INTO tmp_view_text_check (owner, view_name, view_text)
SELECT owner, view_name, TO_LOB(text)
FROM all_views;

COMMIT;

SELECT owner, view_name
FROM tmp_view_text_check
WHERE UPPER(view_text) LIKE '%SALESYS.%' OR UPPER(view_text) LIKE '%SALESYSFLOW.%';

-- 查完记得删掉这张临时表。
-- Drop the scratch table once you're done checking.
DROP TABLE tmp_view_text_check PURGE;
