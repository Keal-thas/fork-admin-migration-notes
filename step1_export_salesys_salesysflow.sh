#!/usr/bin/env bash
# Step 1 of the Oracle copy: generate portable .dmp export files for
# SALESYS and SALESYSFLOW. Exported as two SEPARATE jobs, each
# connecting as that schema's own owner -- exporting your own schema
# needs no elevated Data Pump role (DATAPUMP_EXP_FULL_DATABASE),
# only a DIRECTORY object with READ/WRITE granted to it.
#
# Run locally on the DB server itself (you're already SSH'd in) -- no
# host/port/service connect string needed, this uses a local bequeath
# connection. The only environment value that matters is ORACLE_SID,
# and it's passed inline on each command (not exported into the shared
# shell), so it never leaks into another user's session on this box.
#
# --- VALUES YOU NEED TO FILL IN -- do not run as-is ---
#
# 1) ORACLE_SID : find it with `cat /etc/oratab` (format is
#    SID:ORACLE_HOME:Y/N, one line per instance on this box) and pick
#    the right one if there's more than one instance.
# 2) DIR_PATH   : a real OS path on this server, writable by whichever
#    OS user runs these commands (oracle, if you sudo su - oracle
#    first), where the .dmp/.log files land. Suggest something like
#    /home/oracle/dumps if you don't already have a convention -- just
#    make sure there's enough disk space for ~400+ tables of data.
# 3) SALESYS_PWD / SALESYSFLOW_PWD : their passwords (you have these).

ORACLE_SID="__FILL_IN__"     # e.g. from `cat /etc/oratab`
DIR_PATH="__FILL_IN__"       # e.g. /home/oracle/dumps
SALESYS_PWD="__FILL_IN__"
SALESYSFLOW_PWD="__FILL_IN__"

# --- One-time setup: run this section ONCE as the oracle OS user, via
# sqlplus / as sysdba (local OS authentication -- no separate DB
# password needed for this part). Creates the DIRECTORY object and
# grants the two schema owners access to it. ---
#
#   sudo su - oracle
#   sqlplus -s / as sysdba <<SQL
#   CREATE DIRECTORY DP_DIR AS '${DIR_PATH}';
#   GRANT READ, WRITE ON DIRECTORY DP_DIR TO SALESYS;
#   GRANT READ, WRITE ON DIRECTORY DP_DIR TO SALESYSFLOW;
#   EXIT;
#   SQL

# --- Actual export: two independent jobs, no shared state between them.
# ORACLE_SID is set inline per-command, not exported into the shell,
# so it doesn't affect any other session on this shared server. ---

ORACLE_SID="${ORACLE_SID}" expdp "SALESYS/${SALESYS_PWD}" \
  SCHEMAS=SALESYS \
  DIRECTORY=DP_DIR \
  DUMPFILE=salesys_export.dmp \
  LOGFILE=salesys_export.log

ORACLE_SID="${ORACLE_SID}" expdp "SALESYSFLOW/${SALESYSFLOW_PWD}" \
  SCHEMAS=SALESYSFLOW \
  DIRECTORY=DP_DIR \
  DUMPFILE=salesysflow_export.dmp \
  LOGFILE=salesysflow_export.log
