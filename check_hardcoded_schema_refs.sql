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
-- 注意:ALL_VIEWS.TEXT 是 LONG 类型。Oracle 规定 LONG 列根本不能出现
-- 在 WHERE 子句里 -- 不只是不能包函数(UPPER 会报 ORA-00932),连
-- 裸的 `WHERE text LIKE ...` 也一样不行(这是 LONG 类型本身的限制,
-- 不是函数的问题)。唯一的绕过办法:把 LONG 的值 SELECT INTO 一个
-- PL/SQL 的 VARCHAR2 变量 -- 赋值不受这条限制,只有 SQL 语句的
-- WHERE/函数才受限 -- 然后在 PL/SQL 里做字符串匹配,不在 SQL 里做。
-- Note: ALL_VIEWS.TEXT is a LONG column. Oracle does not allow a LONG
-- column in a WHERE clause AT ALL -- not just wrapped in a function
-- (UPPER raises ORA-00932), a bare `WHERE text LIKE ...` fails too
-- (this is a restriction on the LONG type itself, not on functions).
-- The only way around it: SELECT the LONG value INTO a PL/SQL
-- VARCHAR2 variable -- assignment isn't subject to this restriction,
-- only a SQL statement's WHERE/functions are -- then do the string
-- match in PL/SQL instead of in SQL.

SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
  v_text all_views.text%TYPE;
BEGIN
  FOR rec IN (SELECT owner, view_name FROM all_views) LOOP
    BEGIN
      -- 把这一个视图的 LONG 定义读进变量(逐行/逐视图读,不在 WHERE 里筛)
      -- Read this one view's LONG definition into a variable (per-view,
      -- not filtered in a WHERE clause)
      SELECT text INTO v_text
      FROM all_views
      WHERE owner = rec.owner AND view_name = rec.view_name;

      IF UPPER(v_text) LIKE '%SALESYS.%' OR UPPER(v_text) LIKE '%SALESYSFLOW.%' THEN
        DBMS_OUTPUT.PUT_LINE(rec.owner || '.' || rec.view_name);
      END IF;
    EXCEPTION
      -- 极少数视图定义超过 32767 字符会放不进 VARCHAR2,跳过并提示,
      -- 而不是让整个循环中断。
      -- The rare view definition longer than 32767 chars won't fit in
      -- VARCHAR2 -- skip it with a note instead of aborting the loop.
      WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('SKIPPED (too long to check): ' || rec.owner || '.' || rec.view_name);
    END;
  END LOOP;
END;
/
