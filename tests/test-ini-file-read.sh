#!/bin/bash

. ../bash-ini-parser.sh

# Syntax: assert_file_read <raw_buffer> <expected_string> <unittest_note>
assert_file_read() {
  local raw_buffer expected note result ini_buffer
  raw_buffer=$1
  expected=$2
  note=$3
  ini_buffer="$(ini_file_read "$raw_buffer")"
  printf "assert_file_read(): "
  if [ "$ini_buffer" = "$expected" ]; then
    printf "passed: # %s\n" "$note"
  else
    printf "fail: # %s\n  expected: %s\n  actual:   %s\n" \
           "$note" "$expected" "$ini_buffer"
    echo "Aborted."
    exit 1
  fi
}

assert_file_read ";" "" "comment ;"
assert_file_read "#" "" "comment #"
assert_file_read "# comment" "" "full comment #"
assert_file_read "DNS=" "[Default]DNS=" "no-section no-value"
assert_file_read "DNS=   # inline comment" "[Default]DNS=" "no-section no-value inline-comment"
assert_file_read "[Default]
DNS=" "[Default]DNS=" "section no-value"
assert_file_read "[Default]
DNS=4.4.4.4" "[Default]DNS=4.4.4.4" "section keyvalue"
assert_file_read "[Default]
DNS=\"4.4.4.4\"" "[Default]DNS=\"4.4.4.4\"" "section keyvalue"
assert_file_read "[ prefixed_space]DNS=" "[prefixed_space]DNS=" "prefixed-space no-value"

assert_file_read "[ prefixed_space]DNS=" "[prefixed_space]DNS=" "prefixed-space no-value"

assert_file_read "[Machine1]
app=version1" "[Machine1]app=version1" "StackOverflow"


# Posted by Ras of StackOverflow
# https://stackoverflow.com/questions/49399984/parsing-ini-file-in-bash
assert_file_read "[Machine1]

app=version1


[Machine2]

app=version1

app=version2

[Machine3]

app=version1
app=version3" "[Machine1]app=version1
[Machine2]app=version1
[Machine2]app=version2
[Machine3]app=version1
[Machine3]app=version3" "Ras of StackOverflow"
echo

echo "${BASH_SOURCE[0]}: Done."
