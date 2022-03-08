#!/bin/bash

. ../bash-ini-parser.sh

assert_section_normalize() {
  local section expected pass note result
  section=$1
  expected=$2
  pass=$3
  note=$4
  printf "assert_section_normalize('%s'): " "${section}" >&2
  result="$(ini_section_name_normalize "$section")"
  if [ "$result" == "$section" ]; then
    if [ "$pass" == '1' ]; then
      printf "pass: got '%s': # %s\n" "$result" "$note" >&2
    else
      printf "UNEXPECTEDLY FAILED: # %s\n  expected: '%s'\n  actual: '%s'\n" \
             "$note" "$expected" "$result" >&2
      dump_string_char "$result"
      echoerr "Aborted."
      exit 1
    fi
  else
    if [ "$pass" == '0' ]; then
      printf "expectedly fail: got '%s' # %s\n" "$result" "$note" >&2
    else
      printf "UNEXPECTEDLY PASSED: # %s\n  expected: '%s'\n  actual: '%s'\n" \
             "$note" "$expected" "$result" >&2
      dump_string_char "$result"
      echoerr "Aborted."
      exit 1
    fi
  fi
}


assert_section_normalize "DNS" "DNS" 1 "basic section"
assert_section_normalize "ini_field" "ini_field" 1 "underscore"
assert_section_normalize "ini-field" "ini-field" 1 "dash symbol"
assert_section_normalize "ini\$field" "ini\$field" 1 "dollar-sign"
assert_section_normalize "ini\$field-play_er" "ini\$field-play_er" 1 "mixed symbols"
assert_section_normalize "ini.field" "ini.field" 1 "period"

assert_section_normalize "D NS" "DNS" 0 "spacey section"
assert_section_normalize " DNS" "DNS" 0 "space-prefixed section"
assert_section_normalize "DNS " "DNS" 0 "space-suffixed section"
assert_section_normalize "D#NS" "DNS" 0 "hashmark"
assert_section_normalize "D~NS" "DNS" 0 "tilde"
assert_section_normalize "D\`NS" "DNS" 0 "backtick"
assert_section_normalize "D!NS" "DNS" 0 "exclaimation mark"
assert_section_normalize "D@NS" "DNS" 0 "at symbol"
assert_section_normalize "D%NS" "DNS" 0 "percent"
assert_section_normalize "D^NS" "DNS" 0 "caret"
assert_section_normalize "D*NS" "DNS" 0 "asterisk"
assert_section_normalize "D(NS" "DNS" 0 "left parenthesis"
assert_section_normalize "D)NS" "DNS" 0 "right parenthesis"
assert_section_normalize "D+NS" "DNS" 0 "plus"
assert_section_normalize "D=NS" "DNS" 0 "equal"
assert_section_normalize "D]NS" "DNS" 0 "right brack"
assert_section_normalize "D[NS" "DNS" 0 "left brack"
assert_section_normalize "D{NS" "DNS" 0 "left brace"
assert_section_normalize "D}NS" "DNS" 0 "right brace"
assert_section_normalize "D,NS" "DNS" 0 "comma"
assert_section_normalize "D<NS" "DNS" 0 "less than"
assert_section_normalize "D>NS" "DNS" 0 "greater than"

assert_section_normalize "D/NS" "DNS" 0 "slash"
assert_section_normalize "D//NS" "DNS" 0 "double slash"
assert_section_normalize "D//NS" "DNS" 0 "triple slash"

###assert_section_normalize 'D\bS' "DS" 0 "bell1"   # wow, bash limitation there
###assert_section_normalize "D\bS" "DS" 0 "bell2"   # wow, bash limitation there
###assert_section_normalize 'D\\bS' "DS" 0 "bell3"   # wow, bash limitation there
###assert_section_normalize "D\tS" "DS" 0 "tab"   # wow, bash limitation there
###assert_section_normalize "D\nS" "DS" 0 "new-line"   # wow, bash limitation there
###assert_section_normalize "D\AS" "DNS" 0 "backslash1"   # wow, bash limitation there
###assert_section_normalize "D\nS" "DnS" 0 "backslash2"   # wow, bash limitation there
###assert_section_normalize 'D\\nS' "DnS" 0 "double backslash1"
###assert_section_normalize "D\\nS" "DnS" 0 "double backslash2"
###assert_section_normalize 'D\\\nS' "DnS" 0 "triplebackslash1"
###assert_section_normalize "D\\\nS" "DnS" 0 "triplebackslash2"

###assert_section_normalize "D\rS" "DS" 0 "backslash"   # wow, bash limitation there
echo

echo "${BASH_SOURCE[0]}: Done."

