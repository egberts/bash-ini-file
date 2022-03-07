#!/bin/bash

# echo "Unit-test section-regex.sh bash module"

. ./test-ini-file-read.sh
. ./test-ini-section-name-normalize.sh
. ./test-ini-section-list.sh
. ./test-ini-section-extract.sh
. ./test-ini-section-test.sh
. ./test-ini-keyword-normalize.sh
. ./test-ini-keyword-valid.sh
. ./test-ini-keyword-list.sh
. ./test-ini-keyvalue-get.sh
. ./test-ini-kv-get-last.sh
echo ""

echo "${BASH_SOURCE[0]}: Done."

