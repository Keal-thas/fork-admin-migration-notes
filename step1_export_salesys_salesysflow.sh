#!/usr/bin/env bash
# Step 1 of the Oracle copy: generate portable .dmp export files for
# SALESYS and SALESYSFLOW. Exported as two SEPARATE jobs, each
# connecting as that schema's own owner -- exporting your own schema
# needs no elevated Data Pump role (DATAPUMP_EXP_FULL_DATABASE),
# only a DIRECTORY object with READ/WRITE granted to it. This avoids
# needing to know whether the schema-owner accounts have any extra
# privileges.
#
# No parameter file, no reliance on ambient shell env vars (ORACLE_SID
# etc.) -- every value is explicit on the command line, safe on a
# server shared with other users.
#
# --- VALUES YOU NEED TO FILL IN -- do not run as-is ---
#
# 1) DIR_PATH   : a real OS path on the DB server, owned/writable by
#                 the `oracle` OS user, where the .dmp/.log files land.
# 2) DB_HOST    : hostname or IP of the database listener.
# 3) DB_PORT    : listener port (commonly 1521, confirm your setup).
# 4) DB_SERVICE : the service name (or SID) to connect to.
# 5) SALESYS_USER / SALESYSFLOW_USER : the ACTUAL login usernames for
#    these two schema owners -- confirm these are literally SALESYS /
#    SALESYSFLOW and not some other account name.
# 6) SALESYS_PWD / SALESYSFLOW_PWD   : their passwords.

DIR_PATH="__FILL_IN__"       # e.g. /u01/dumps
DB_HOST="__FILL_IN__"        # e.g. localhost, if running this on the DB server itself
DB_PORT="__FILL_IN__"        # e.g. 1521
DB_SERVICE="__FILL_IN__"     # e.g. ORCLPDB1
SALESYS_USER="__FILL_IN__"
SALESYS_PWD="__FILL_IN__"
SALESYSFLOW_USER="__FILL_IN__"
SALESYSFLOW_PWD="__FILL_IN__"

# --- One-time setup: run this section ONCE as the oracle OS user, via
# sqlplus / as sysdba (local OS authentication -- no separate DB
# password needed for this part). Creates the DIRECTORY object and
# grants the two schema owners access to it. ---
#
#   sudo su - oracle
#   sqlplus -s / as sysdba <<SQL
#   CREATE DIRECTORY DP_DIR AS '${DIR_PATH}';
#   GRANT READ, WRITE ON DIRECTORY DP_DIR TO ${SALESYS_USER};
#   GRANT READ, WRITE ON DIRECTORY DP_DIR TO ${SALESYSFLOW_USER};
#   EXIT;
#   SQL

# --- Actual export: two independent jobs, no shared state between them ---

expdp "${SALESYS_USER}/${SALESYS_PWD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE}" \
  SCHEMAS="${SALESYS_USER}" \
  DIRECTORY=DP_DIR \
  DUMPFILE=salesys_export.dmp \
  LOGFILE=salesys_export.log

expdp "${SALESYSFLOW_USER}/${SALESYSFLOW_PWD}@//${DB_HOST}:${DB_PORT}/${DB_SERVICE}" \
  SCHEMAS="${SALESYSFLOW_USER}" \
  DIRECTORY=DP_DIR \
  DUMPFILE=salesysflow_export.dmp \
  LOGFILE=salesysflow_export.log
