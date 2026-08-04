#!/usr/bin/env bash
# 在应用源码里查找硬编码的 schema 前缀引用(SALESYS.xxx / SALESYSFLOW.xxx)。
# 一旦目标端 schema 改名(加前缀)导入,这些引用就会失效。
# Search application source for hardcoded schema-qualified table
# references (SALESYS.xxx / SALESYSFLOW.xxx), which will break once
# the schemas are imported under renamed (prefixed) users.
#
# 不是用来 `bash check_hardcoded_schema_refs.sh` 一次性跑的 --
# 按下面编号的两步,把每条命令单独复制粘贴到终端执行。
# NOT meant to be run as `bash check_hardcoded_schema_refs.sh` --
# copy/paste each numbered command below one at a time.

# ------------------------------------------------------------------
# 1. 设置项目源码的真实路径(把右边换成你自己的路径)。
#    Set the real path to your project source (replace the value below).
# ------------------------------------------------------------------

SRC_DIR=/path/to/project/source

# ------------------------------------------------------------------
# 2. 执行搜索:只看 .java / .xml / .sql / .yml / .yaml / .properties
#    文件里的 SALESYS. 或 SALESYSFLOW. 引用(不区分大小写)。
#    排除 local 目录(本地/临时文件,不属于应用源码)。
#    Run the search: only .java / .xml / .sql / .yml / .yaml /
#    .properties files, matching SALESYS. or SALESYSFLOW. (case
#    insensitive). Excludes the "local" directory (local/scratch
#    files that aren't part of the application source).
# ------------------------------------------------------------------

grep -rniE --exclude-dir='local' --include='*.java' --include='*.xml' --include='*.sql' --include='*.yml' --include='*.yaml' --include='*.properties' '\b(SALESYS|SALESYSFLOW)\.' "$SRC_DIR"
