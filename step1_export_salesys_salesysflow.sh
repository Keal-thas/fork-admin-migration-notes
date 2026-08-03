#!/usr/bin/env bash
# Step 1 of the Oracle copy: generate portable .dmp export files for
# SALESYS and SALESYSFLOW. Exported as two SEPARATE jobs, each
# connecting as that schema's own owner -- exporting your own schema
# needs no elevated Data Pump role (DATAPUMP_EXP_FULL_DATABASE), only
# a DIRECTORY object with READ/WRITE granted to it.
#
# NOT meant to be run as `bash step1_export_salesys_salesysflow.sh` --
# copy/paste each numbered block below one at a time on the DB server
# (you're already SSH'd in as the oracle OS user).
#
# Confirmed values for this server:
#   ORACLE_SID = orcl
#   DIR_PATH   = /home/oracle/dumps
#
# Passwords are NOT written anywhere in this file. expdp prompts for
# them interactively when you omit the password from the connect
# string -- typing it at the prompt means it never lands in shell
# history or becomes visible to other users on this shared server via
# `ps -ef`.

# ------------------------------------------------------------------
# 0. Check free disk space at the target directory before exporting
#    (400+ tables combined across both schemas).
# ------------------------------------------------------------------

df -h /home/oracle

# ------------------------------------------------------------------
# 1. Create the OS directory (skip if it already exists).
# ------------------------------------------------------------------

mkdir -p /home/oracle/dumps

# ------------------------------------------------------------------
# 2. One-time DB setup: create the Oracle DIRECTORY object and grant
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
# 3. Export SALESYS. You'll be prompted for the SALESYS password --
#    it won't echo to the terminal.
# ------------------------------------------------------------------

ORACLE_SID=orcl expdp SALESYS DIRECTORY=DP_DIR DUMPFILE=salesys_export.dmp LOGFILE=salesys_export.log SCHEMAS=SALESYS

# ------------------------------------------------------------------
# 4. Export SALESYSFLOW. Separate job, own password prompt.
# ------------------------------------------------------------------

ORACLE_SID=orcl expdp SALESYSFLOW DIRECTORY=DP_DIR DUMPFILE=salesysflow_export.dmp LOGFILE=salesysflow_export.log SCHEMAS=SALESYSFLOW

# ------------------------------------------------------------------
# 5. After both finish: confirm the files landed and neither log
#    shows an ORA- error.
# ------------------------------------------------------------------

ls -lh /home/oracle/dumps
grep -i "ORA-" /home/oracle/dumps/salesys_export.log /home/oracle/dumps/salesysflow_export.log
