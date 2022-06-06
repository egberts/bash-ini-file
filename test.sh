#!/bin/bash

source bash-ini-parser.sh
read -rd '' raw_data < <(cat "/etc/systemd/system/display-manager.service")
read -rd '' ini_service_section < <(ini_file_read "$raw_data")
ini_keyvalue_get "$ini_service_section" "Service" "ExecStart"
echo

