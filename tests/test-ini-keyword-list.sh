#!/bin/bash

. ../bash-ini-parser.sh

assert_keyword_list()
{
  local ini_buffer section expected note ini_buf_by_section result
  ini_buffer=$1
  section=$2
  expected=$3
  note=$4
  ini_buf_by_section="$(ini_section_extract "$ini_buffer" "$section")"
  result="$(ini_keyword_list "$ini_buf_by_section")"
  printf "assert_keyword_list([%s]): " "$section" >&2
  if [ "$result" = "$expected" ]; then
    printf "passed: # %s\n" "$note" >&2
  else
    printf "FAILED: NOT FOUND # %s\n  expected: '%s'\n  actual  : '%s'\n" "$note" "$expected" "$result" >&2
    printf "Aborted.\n" >&2
    exit 1
  fi
}

assert_keyword_list_raw()
{
  local raw_data section expected note ini_buffer ini_buf_by_section result
  raw_data=$1
  section=$2
  expected=$3
  note=$4
  ini_buffer="$(ini_file_read "$raw_file")"
  ini_buf_by_section="$(ini_section_extract "$ini_buffer" "$section")"
  result="$(ini_keyword_list "$ini_buf_by_section")"
  printf "assert_keyword_list_raw([%s]): " "$section" >&2
  if [ "$result" == "$expected" ]; then
    printf "passed: # %s\n" "$note" >&2
  else
    printf "FAILED: NOT FOUND # %s\n" "$note" >&2
    printf "Aborted.\n" >&2
    exit 1
  fi
}

raw_file="$(
  cat <<TEST_EOF

TEST_EOF
)"
assert_keyword_list_raw "$raw_file" "Default" "" "Empty keyvalue"

raw_file="$(
  cat <<TEST_EOF
[Default]
DNS=1.1.1.1
TEST_EOF
)"
assert_keyword_list_raw "$raw_file" "Default" "DNS" "standard, Default"

raw_file="$(
  cat <<TEST_EOF
[Default]
DNS = 2.2.2.2
TEST_EOF
)"
assert_keyword_list_raw "$raw_file" "Default" "DNS" "leading spaces"

raw_file="$(
  cat <<TEST_EOF
DNS=0.0.0.0
[Default]
DNS=1.1.1.1
TEST_EOF
)"
assert_keyword_list_raw "$raw_file" "Default" "DNS" "mixed default keywords"

raw_file="$(
  cat <<TEST_EOF
[Default]DNS=0.0.0.0
TEST_EOF
)"
assert_keyword_list_raw "$raw_file" "Default" "DNS" "[Default]"

raw_file="$(
  cat <<TEST_EOF
[Default]DNS=0.0.0.0
[Default]DNS=1.1.1.1
[Resolve]
TEST_EOF
)"

# Exercise that '[Default]' gets inserted for no-section line records
raw_file="$(
  cat <<TEST_EOF
DNS=0.0.0.0
TEST_EOF
)"
assert_keyword_list_raw "$raw_file" "Default" "DNS" "standard, no-section"

raw_file="$(
  cat <<TEST_EOF
DNS=
DNS=0.0.0.0
TEST_EOF
)"
assert_keyword_list_raw "$raw_file" "Default" "DNS" "multi-line"

raw_file="$(
  cat <<TEST_EOF
[Default]
DNS=
TEST_EOF
)"
assert_keyword_list_raw "$raw_file" "Default" "DNS" "default empty-keyvalue"


# empty keyword do not get an entry in our internal 'ini_buffer'
assert_keyword_list_raw "$raw_file" "NotKnown" "" "empty keyword"
echo

ini_buffer="$(
  cat <<TEST_EOF
[Default]DNS=0.0.0.0
[Default]DNS=0.0.0.1
[Unknown]DNS=0.0.0.2
[Unknown]DNS=0.0.0.3
[Resolve]DNS=0.0.0.4
[Resolve]DNS=0.0.0.5
[Resolve]DNS=0.0.0.6
[Network]D\$NS=0.0.0.7
[Network]D_NS=0.0.0.8
[Network]D-NS=0.0.0.9
[Default]DNS=1.1.1.1
TEST_EOF
)"

assert_keyword_list "$ini_buffer" "Default" "DNS" "no-keyword mixed-default"

# has no 'Default' section name
ini_buffer="$(
  cat <<TEST_EOF
[Default]DNS=0.0.1.0
[Default]DNS=0.0.1.1
[Unknown]DNS=0.0.1.2
[Unknown]DNS=0.0.1.3
[Resolve]DNS=0.0.1.4
[Resolve]DNS=0.0.1.5
[Resolve]DNS=0.0.1.6
[Network]D\$NS=0.0.1.7
[Network]D_NS=0.0.1.8
[Network]D-NS=0.0.1.9
[Default]DNS=2.2.2.2
TEST_EOF
)"

assert_keyword_list "$ini_buffer" "" "" "no-section no-keyword1"

assert_keyword_list "$ini_buffer" "NotUsed" "" "unused-section no-keyword1"
assert_keyword_list "$ini_buffer" "Default" "DNS" "[Default] no-keyword1"
assert_keyword_list "$ini_buffer" "Resolve" "DNS" "valid-section no-keyword1"


# has multiple intersperseed Section Names
ini_buffer="$(
  cat <<TEST_EOF
[Default]ABC=0.2.0.0
[Default]DEF=0.2.0.1
[Unknown]GHI=0.2.0.2
[Resolve]JKL=0.2.0.4
[Unknown]MNO=0.2.0.3
[Resolve]PQR=0.2.0.5
[Network]STU=0.2.0.7
[Resolve]VWX=0.2.0.6
[Network]XYZ=0.2.0.8
[Network]ABCS=0.2.0.9
[Default]DEFS=3.3.3.3
TEST_EOF
)"

assert_keyword_list "$ini_buffer" "" "" "no-section no-keyword"

assert_keyword_list "$ini_buffer" "NotUsed" "" "unused-section no-keyword"
assert_keyword_list "$ini_buffer" "Default" "ABC DEF DEFS" "[Default] keyword"
assert_keyword_list "$ini_buffer" "Resolve" "JKL PQR VWX" "valid-section no-keyword"
echo

echo "${BASH_SOURCE[0]}: Done."

