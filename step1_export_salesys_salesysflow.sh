#!/usr/bin/env bash
# Oracle 拷贝 Step 1:为 SALESYS 和 SALESYSFLOW 生成可移植的 .dmp 导出
# 文件。拆成两个独立的 job,各自用该 schema 自己的 owner 账号连接 --
# 导出自己名下的 schema 不需要更高权限的 Data Pump 角色
# (DATAPUMP_EXP_FULL_DATABASE),只需要一个被授予 READ/WRITE 的
# DIRECTORY 对象。
# Step 1 of the Oracle copy: generate portable .dmp export files for
# SALESYS and SALESYSFLOW. Exported as two SEPARATE jobs, each
# connecting as that schema's own owner -- exporting your own schema
# needs no elevated Data Pump role (DATAPUMP_EXP_FULL_DATABASE), only
# a DIRECTORY object with READ/WRITE granted to it.
#
# 不是用来 `bash step1_export_salesys_salesysflow.sh` 一次性跑的 --
# 在 DB 服务器上(已经 SSH 进去、是 oracle 这个 OS 用户)按下面编号的
# 每一块,一条一条手动复制粘贴执行。
# NOT meant to be run as `bash step1_export_salesys_salesysflow.sh` --
# copy/paste each numbered block below one at a time on the DB server
# (you're already SSH'd in as the oracle OS user).
#
# *** 截至 2026-08-04 已过期:下面的 DIR_PATH 还是 /home/oracle/dumps,
# 但那个分区导出到一半就写满了 100%(SALESYSFLOW 导出失败,报
# "master table failed to load/unload"),当时定的计划是把所有东西
# 挪到 /opt/dumps。这个挪动动作在做决定的那次会话里**没有确认执行
# 完成** -- 用下面任何 DIR_PATH 值之前,先看 WORK_LOG.md 里
# "disk-full incident" 那条完整的恢复清单。 ***
# *** STALE as of 2026-08-04: DIR_PATH below is /home/oracle/dumps,
# but that partition filled to 100% mid-export (SALESYSFLOW failed
# with a "master table failed to load/unload" error) and the plan
# was to move everything to /opt/dumps instead. Execution of that
# move was NOT confirmed finished in the session that decided it --
# see the "disk-full incident" entry in WORK_LOG.md for the full
# recovery checklist before trusting any DIR_PATH value below. ***
#
# 本服务器已确认的值:
# Confirmed values for this server:
#   ORACLE_SID = orcl
#   DIR_PATH   = /home/oracle/dumps(见上面的过期警告 / see stale-warning above)
#
# 密码不会写在这个文件里的任何地方。connect string 里不带密码时,
# expdp 会交互式提示输入 -- 这样密码既不会留在 shell 历史里,也不会
# 在这台共享服务器上被别人用 `ps -ef` 看到。
# Passwords are NOT written anywhere in this file. expdp prompts for
# them interactively when you omit the password from the connect
# string -- typing it at the prompt means it never lands in shell
# history or becomes visible to other users on this shared server via
# `ps -ef`.

# ------------------------------------------------------------------
# 0. 导出前先检查目标目录的可用磁盘空间(两个 schema 合计 400+ 张表)。
#    Check free disk space at the target directory before exporting
#    (400+ tables combined across both schemas).
# ------------------------------------------------------------------

df -h /home/oracle

# ------------------------------------------------------------------
# 1. 创建 OS 目录(如果已存在则跳过)。
#    Create the OS directory (skip if it already exists).
# ------------------------------------------------------------------

mkdir -p /home/oracle/dumps

# ------------------------------------------------------------------
# 2. 一次性的数据库设置:创建 Oracle DIRECTORY 对象,并把两个 schema
#    owner 的访问权限都授予它。用本地 OS 认证的 `sqlplus / as sysdba`
#    -- 这一步不需要单独输入密码。
#    One-time DB setup: create the Oracle DIRECTORY object and grant
#    both schema owners access to it. Local OS auth via
#    `sqlplus / as sysdba` -- no separate password needed for this
#    part.
# ------------------------------------------------------------------

sqlplus -s / as sysdba <<'SQL'
CREATE DIRECTORY DP_DIR AS '/home/oracle/dumps';
GRANT READ, WRITE ON DIRECTORY DP_DIR TO SALESYS;
GRANT READ, WRITE ON DIRECTORY DP_DIR TO SALESYSFLOW;
EXIT;
SQL

# ------------------------------------------------------------------
# 3. 导出 SALESYS。会提示输入 SALESYS 的密码 -- 输入时不会回显。
#    Export SALESYS. You'll be prompted for the SALESYS password --
#    it won't echo to the terminal.
# ------------------------------------------------------------------

ORACLE_SID=orcl expdp SALESYS DIRECTORY=DP_DIR DUMPFILE=salesys_export.dmp LOGFILE=salesys_export.log SCHEMAS=SALESYS

# ------------------------------------------------------------------
# 4. 导出 SALESYSFLOW。独立的 job,单独提示输入密码。
#    Export SALESYSFLOW. Separate job, own password prompt.
# ------------------------------------------------------------------

ORACLE_SID=orcl expdp SALESYSFLOW DIRECTORY=DP_DIR DUMPFILE=salesysflow_export.dmp LOGFILE=salesysflow_export.log SCHEMAS=SALESYSFLOW

# ------------------------------------------------------------------
# 5. 两个都跑完之后:确认文件确实生成了,并且两份日志里都没有
#    ORA- 报错。
#    After both finish: confirm the files landed and neither log
#    shows an ORA- error.
# ------------------------------------------------------------------

ls -lh /home/oracle/dumps
grep -i "ORA-" /home/oracle/dumps/salesys_export.log /home/oracle/dumps/salesysflow_export.log
