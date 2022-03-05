#!/bin/bash
# File: example-usage.sh
# Title: Demo of bash-ini-parser.sh
# 

source bash-ini-parser.sh

my_raw="$(cat /etc/systemd/system/display-manager.service)"

my_ini="$(ini_file_read "$my_ini")"

ini_kw_get "$my_ini" "Service" "ExecStart"

