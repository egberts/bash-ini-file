#!/bin/bash
# File: example-usage.sh
# Title: Demo of bash-ini-parser.sh
# 

ini_filespec="/etc/systemd/system/display-manager.service"
section="Service"
keyword="ExecStart"

. ./bash-ini-parser.sh

raw_data="$(cat $ini_filespec)"

ini_settings="$(ini_file_read "$raw_data")"

keyvalue="$(ini_keyvalue_get "$ini_settings" "$section" "$keyword")"
retsts=$?
if [ $retsts -ne 0 ]; then
  echoerr "Error $retsts in ini_keyvalue_get(); aborted."
  exit $retsts
fi

echo "File    : $ini_filespec"
echo "Keyword : $keyword"
echo "Keyvalue: $keyvalue  # <--- your section/keyword/keyvalue answer"
echo
echo "Came from all that below:"
echo "\"$ini_settings\""
echo
echo "Done."
