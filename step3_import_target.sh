#!/usr/bin/env bash
# Oracle 拷贝 Step 3:在目标端把 SALESYS / SALESYSFLOW 的 .dmp 导入成
# 新的、加了 HR_ 前缀的 schema(HR_SALESYS / HR_SALESYFLOW),让系统 B
# 完全独立于系统 A 的数据库。
# Step 3 of the Oracle copy: import SALESYS / SALESYSFLOW's .dmp files
# on the target host as new schemas prefixed with HR_ (HR_SALESYS /
# HR_SALESYFLOW), so system B runs fully independent of system A's
# database.
#
# 不是用来一次性跑的 -- 按编号一块一块手动复制粘贴执行,遇到打了
# 【占位符】标记的地方,先换成真实值再跑那一块。
# NOT meant to be run in one shot -- copy/paste each numbered block by
# hand. Anywhere marked 【占位符 / PLACEHOLDER】, replace with the real
# value before running that block.
#
# *** 下面这些值目前还不知道,都是占位符,还没确认:
#     目标 Oracle 19c 实例的连接信息(主机/ORACLE_SID)、目标端存放
#     .dmp 文件的目录、目标端表空间怎么建。Schema 前缀已确认为 HR_。
# *** The following are still unknown / unconfirmed placeholders:
#     the target Oracle 19c instance's connection info (host/
#     ORACLE_SID), the directory on the target host to hold the .dmp
#     files, how the target tablespace should be created. The schema
#     prefix IS confirmed: HR_.

# ------------------------------------------------------------------
# 0. 确认目标端已经有一个可用的 Oracle 19c 实例(SSH 进目标主机,
#    sudo su - oracle 之后跑):
#    Confirm the target host already has a usable Oracle 19c instance
#    (after SSH'ing in and `sudo su - oracle`):
# ------------------------------------------------------------------

echo $ORACLE_SID
# 【占位符 / PLACEHOLDER】上面这行如果输出为空,说明这台机器的 shell
# 没预置 ORACLE_SID,需要你手动确认实例名(问管理员,或者
# `ps -ef | grep pmon` 看 ora_pmon_<SID> 进程名)。
# If the above prints nothing, this shell has no ORACLE_SID preset --
# confirm the instance name manually (ask the admin, or check
# `ps -ef | grep pmon` for the ora_pmon_<SID> process name).

# ------------------------------------------------------------------
# 1. 检查目标端字符集是否和源端(ZHS16GBK,已确认)一致 -- 不一致会
#    静默损坏中文,不会报错,必须先查清楚。
#    Check the target's character set matches the source
#    (ZHS16GBK, confirmed) -- a mismatch silently corrupts Chinese
#    text with no error, must be checked before importing.
# ------------------------------------------------------------------

sqlplus -s / as sysdba <<'SQL'
SELECT parameter, value FROM nls_database_parameters WHERE parameter = 'NLS_CHARACTERSET';
EXIT;
SQL
# 【占位符 / PLACEHOLDER】如果这里的结果不是 ZHS16GBK(或者不是它的
# 超集),先停下来 -- 不要继续导入,回来找源端和目标端的字符集怎么
# 对齐。
# If this does not return ZHS16GBK (or a proper superset of it), stop
# here -- do not continue importing until the source/target character
# sets are reconciled.

# ------------------------------------------------------------------
# 2. 把 .dmp 文件从本地 Windows 机器传到目标 Oracle 主机(如果目标
#    主机跟你本地拉文件时用的不是同一台机器)。
#    Transfer the .dmp files from your local Windows machine to the
#    target Oracle host (if the target host isn't the same machine
#    you already pulled them to locally).
# ------------------------------------------------------------------

# 在本地 git-bash 里执行(把下面全部换成真实值):
# Run this from your local git-bash (replace everything below with
# real values):
#   scp salesys_export.dmp salesysflow_export.dmp \
#     【占位符:目标主机的用户名】@【占位符:目标主机地址】:【占位符:目标端存放dmp的目录】/

# ------------------------------------------------------------------
# 3. 回源端查两个 schema 用的表空间名(决定要不要 REMAP_TABLESPACE)。
#    On the SOURCE side, check which tablespace(s) these two schemas
#    actually use (decides whether REMAP_TABLESPACE is needed).
# ------------------------------------------------------------------

sqlplus -s / as sysdba <<'SQL'
SELECT username, default_tablespace FROM dba_users WHERE username IN ('SALESYS', 'SALESYSFLOW');
SELECT DISTINCT owner, tablespace_name FROM dba_segments WHERE owner IN ('SALESYS', 'SALESYSFLOW');
EXIT;
SQL

# ------------------------------------------------------------------
# 4. 在目标端创建 DIRECTORY 对象,指向存放 .dmp 文件的目录。
#    On the target, create the DIRECTORY object pointing at wherever
#    the .dmp files landed.
# ------------------------------------------------------------------

sqlplus -s / as sysdba <<'SQL'
CREATE OR REPLACE DIRECTORY DP_DIR_TARGET AS '【占位符:目标端存放dmp的目录】';
EXIT;
SQL

# ------------------------------------------------------------------
# 5. 在目标端建两个新 schema 用户(HR_SALESYS / HR_SALESYFLOW)+
#    表空间。这里先用 USERS 表空间占位,如果要单独建表空间,把
#    CREATE TABLESPACE 那两行取消注释,并换成真实的数据文件路径/大小。
#    On the target, create the two new schema users (HR_SALESYS /
#    HR_SALESYFLOW) + tablespace. Placeholder uses the USERS
#    tablespace for now -- uncomment the CREATE TABLESPACE lines and
#    fill in a real datafile path/size if a dedicated tablespace is
#    wanted instead.
# ------------------------------------------------------------------

sqlplus -s / as sysdba <<'SQL'
-- CREATE TABLESPACE HR_DATA DATAFILE '【占位符:数据文件路径】' SIZE 【占位符:大小,如 2G】 AUTOEXTEND ON;

CREATE USER HR_SALESYS IDENTIFIED BY "【占位符:新密码,不要写死在这个文件里,交互输入】" DEFAULT TABLESPACE USERS;
GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO HR_SALESYS;

CREATE USER HR_SALESYFLOW IDENTIFIED BY "【占位符:新密码,不要写死在这个文件里,交互输入】" DEFAULT TABLESPACE USERS;
GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO HR_SALESYFLOW;
EXIT;
SQL
# 密码原则和 Step 1 一样:不要写进这个文件,改成交互输入 --
# 上面这样写只是先占位提醒你自己动手改。
# Same password principle as Step 1: don't write it into this file --
# the placeholder above is just a reminder to type it in by hand.

# ------------------------------------------------------------------
# 6. 执行导入:REMAP_SCHEMA 把 SALESYS 的对象导入成 HR_SALESYS 拥有,
#    SALESYSFLOW 同理。用 SYSTEM(或其他有 IMP_FULL_DATABASE 权限的
#    账号)连接,因为要跨 schema 建对象,新 schema 自己的账号权限不
#    够。如果第 3 步查出来表空间名不一样,取消注释 REMAP_TABLESPACE
#    那行并填真实的源/目标表空间名。
#    Run the import: REMAP_SCHEMA re-owns SALESYS's objects as
#    HR_SALESYS, same for SALESYSFLOW. Connect as SYSTEM (or another
#    account with IMP_FULL_DATABASE) since creating objects under a
#    different schema needs more than the new schema's own privileges.
#    If step 3 showed a different tablespace name, uncomment
#    REMAP_TABLESPACE and fill in the real source/target names.
# ------------------------------------------------------------------

ORACLE_SID=【占位符:目标端ORACLE_SID】 impdp SYSTEM DIRECTORY=DP_DIR_TARGET DUMPFILE=salesys_export.dmp LOGFILE=salesys_import.log SCHEMAS=SALESYS REMAP_SCHEMA=SALESYS:HR_SALESYS
# REMAP_TABLESPACE=【占位符:源表空间名】:【占位符:目标表空间名】

ORACLE_SID=【占位符:目标端ORACLE_SID】 impdp SYSTEM DIRECTORY=DP_DIR_TARGET DUMPFILE=salesysflow_export.dmp LOGFILE=salesysflow_import.log SCHEMAS=SALESYSFLOW REMAP_SCHEMA=SALESYSFLOW:HR_SALESYFLOW
# REMAP_TABLESPACE=【占位符:源表空间名】:【占位符:目标表空间名】

# ------------------------------------------------------------------
# 7. 验证:两份导入日志里没有 ORA- 报错,跑 utlrp.sql 重编译失效对象,
#    再查一下还剩多少 INVALID 对象。
#    Verify: neither import log shows an ORA- error, run utlrp.sql to
#    recompile invalid objects, then check how many INVALID objects
#    remain.
# ------------------------------------------------------------------

grep -i "ORA-" 【占位符:目标端存放dmp的目录】/salesys_import.log 【占位符:目标端存放dmp的目录】/salesysflow_import.log

sqlplus -s / as sysdba @?/rdbms/admin/utlrp.sql

sqlplus -s / as sysdba <<'SQL'
SELECT owner, object_name, object_type
FROM all_objects
WHERE status = 'INVALID'
  AND owner IN ('HR_SALESYS', 'HR_SALESYFLOW');
EXIT;
SQL
