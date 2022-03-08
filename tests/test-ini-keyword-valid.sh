#!/bin/bash

. ../bash-ini-parser.sh

assert_keyword_valid() {
  local keyword expected note
  keyword="$1"
  expected="$2"
  note="$3"
  ini_keyword_valid "$keyword"
  retsts=$?
  if [ -n "$result" ]; then
    echo "FAIL: Unexpected STDOUT: $result"
    exit 15
  fi
  echo -n "assert_keyword_valid('${keyword}'): "
  if [ "$expected" == "1" ]; then
    if [ $retsts -eq 1 ]; then
      printf "pass	# %s\n" "$note"
    else
      printf "FAIL: INVALID errno # %s\n  expected: '%s'\n  actual  : '%s'\n" \
          "$note" "" "$result"
      echo "Aborted."
      exit 1
    fi
  else
    if [ $retsts -eq 0 ]; then
      printf "correct errno: "
      printf "expectedly failed # %s\n" "$note"
    else
      printf "INVALID errno: "
      printf "unexpectedly PASS: INVALID errno # %s\n  expected: '%s'\n  actual  : '%s'\n" \
          "$note" "" "$result"
      echo "Aborted."
      exit 1
    fi
  fi
}


assert_keyword_valid "DNS" 1 "basic keyword"
assert_keyword_valid "ini_field" 1 "underscore"
assert_keyword_valid "ini-field" 1 "dash symbol"
assert_keyword_valid "ini\$field" 1 "dollar-sign"
assert_keyword_valid "ini\$field-play_er" 1 "mixed symbols"
assert_keyword_valid "D.NS" 1 "period"

assert_keyword_valid "D NS" 0 "spacey keyword"
assert_keyword_valid " DNS" 0 "space-prefixed keyword"
assert_keyword_valid "DNS " 0 "space-suffixed keyword"
assert_keyword_valid "D#NS" 0 "hashmark"
assert_keyword_valid "D~NS" 0 "tilde"
assert_keyword_valid "D\`NS" 0 "backtick"
assert_keyword_valid "D!NS" 0 "exclaimation mark"
assert_keyword_valid "D@NS" 0 "at symbol"
assert_keyword_valid "D%NS" 0 "percent"
assert_keyword_valid "D^NS" 0 "caret"
assert_keyword_valid "D*NS" 0 "asterisk"
assert_keyword_valid "D(NS" 0 "left parenthesis"
assert_keyword_valid "D)NS" 0 "right parenthesis"
assert_keyword_valid "D+NS" 0 "plus"
assert_keyword_valid "D=NS" 0 "equal"
assert_keyword_valid "D]NS" 0 "right brack"
assert_keyword_valid "D[NS" 0 "left brack"
assert_keyword_valid "D{NS" 0 "left brace"
assert_keyword_valid "D}NS" 0 "right brace"
assert_keyword_valid "D,NS" 0 "comma"
assert_keyword_valid "D<NS" 0 "less than"
assert_keyword_valid "D>NS" 0 "greater than"

assert_keyword_valid "D/NS" 0 "slash"
assert_keyword_valid "D//NS" 0 "double slash"
assert_keyword_valid "D//NS" 0 "triple slash"

assert_keyword_valid "D\bS" 0 "bell"   # wow, bash limitation there
assert_keyword_valid "D\tS" 0 "tab"   # wow, bash limitation there
assert_keyword_valid "D\nS" 0 "new-line"   # wow, bash limitation there
assert_keyword_valid "D\AS" 0 "backslash"   # wow, bash limitation there
assert_keyword_valid "D\NS" 0 "backslash"   # wow, bash limitation there
assert_keyword_valid "D\ZS" 0 "backslash"   # wow, bash limitation there
assert_keyword_valid "D\\NS" 0 "double backslash"
assert_keyword_valid "D\\\NS" 0 "triplebackslash"
echo

echo "${BASH_SOURCE[0]}: Done."

