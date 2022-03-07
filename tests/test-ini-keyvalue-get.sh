#!/bin/bash
# File: test-ini-keyvalue-get.sh
# Title: Exercise the Multiline Get Keyvalue(s) From INI data
#
# echo "${BASH_SOURCE[0]}: Started."

. ../bash-ini-parser.sh

assert_keyvalue_get_last() 
{
  local ini_buffer section keyword expected note 
  local found_keywords retsts
  ini_buffer=$1
  section=$2
  keyword=$3
  expected=$4
  note=$5
  ini_keyword_valid "$keyword"
  retsts=$?
  if [ $retsts -eq 0 ]; then
    printf "assert_keyvalue_get_last: invalid keyword: '%s'\nAborted.\n" "$keyword" >&2
    exit 1
  fi
  IFS= read -rd '' found_keywords < <(ini_keyvalue_get_last "$ini_buffer" "$section" "$keyword")

  printf "assert_keyvalue_get_last([%s]%s=): " "$section" "$keyword"
  if [ "$found_keywords" = "$expected" ]; then
    printf "pass # %s\n" "$note"
  else
    printf "failed # %s\n  expected: '%s'\n  actual  : '%s'\n" "$note" "$expected" "$found_keywords" >&2
    printf "Aborted." >&2
    exit 1
  fi
}

assert_keyvalue_get() 
{
  local ini_buffer section keyword expected note 
  local found_keywords retsts
  ini_buffer=$1
  section=$2
  keyword=$3
  expected=$4
  note=$5
  ini_keyword_valid "$keyword"
  retsts=$?
  if [ $retsts -eq 0 ]; then
    printf "assert_keyvalue_get: invalid keyword: '%s'\nAborted.\n" "$keyword" >&2
    exit 1
  fi
  IFS= read -rd '' found_keywords < <(ini_keyvalue_get "$ini_buffer" "$section" "$keyword")

  printf "assert_keyvalue_get([%s]%s=): " "$section" "$keyword"
  if [ "$found_keywords" = "$expected" ]; then
    printf "pass # %s\n" "$note"
  else
    printf "failed # %s\n  expected: '%s'\n  actual  : '%s'\n" "$note" "$expected" "$found_keywords" >&2
    printf "Aborted." >&2
    exit 1
  fi
}


ini_file="[Default]DNS=5.5.5.5
[Resolve]DNS=6.6.6.6
[Gateway]DNS=7.7.7.7"
assert_keyvalue_get "$ini_file" "Default" "DNS" "5.5.5.5" "same keyword, 'Default' section"
assert_keyvalue_get "$ini_file" "Resolve" "DNS" "6.6.6.6" "same keyword, 'Resolve' section"

assert_keyvalue_get "" "Default" "DNS" "" "empty ini_file"
assert_keyvalue_get "
" "Default" "DNS" "" "new line"
assert_keyvalue_get "#" "Default" "DNS" "" "hash mark no-comment"
assert_keyvalue_get ";" "Default" "DNS" "" "semicolon no-comment"
assert_keyvalue_get "//" "Default" "DNS" "" "slash-slash no-comment"
assert_keyvalue_get "# inline comment" "Default" "DNS" "" "hash mark comment"
assert_keyvalue_get "; inline comment" "Default" "DNS" "" "semicolon comment"
assert_keyvalue_get "// inline comment" "Default" "DNS" "" "slash-slash comment"


# Ok, was kinda expecting some error condition, but this is the INI-FORMAT FILE.
# If keyword does not exist, it is really a 'NULL' response thing, not an error
assert_keyvalue_get "$ini_file" "NoSuchSection" "DNS" "" "same keyword, 'NoSuchSection' section"


# Pattern slippage around undersized keyword
ini_file="# comment line
[Default]FallbackDNS=8.8.8.8
[Resolve]DNS_Server1=9.9.9.9
[Gateway]Hidden_DNS_Master=10.10.10.10
"
assert_keyvalue_get "$ini_file" "" "" "" "unused keyword"
assert_keyvalue_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_keyvalue_get "$ini_file" "Resolve" "DNS" "" "unused keyword, 'Resolve' section"
assert_keyvalue_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"

# Pattern slippage with whitespace around undersized keyword
ini_file="# comment line
[Default]FallbackDNS=11.11.11.11
[Resolve] DNS_Server1=12.12.12.12
[Gateway]Hidden_DNS_Master=13.13.13.13
"
assert_keyvalue_get "$ini_file" "" "" "" "unused keyword"
assert_keyvalue_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_keyvalue_get "$ini_file" "Resolve" "DNS" "" "unused keyword, 'Resolve' section"
assert_keyvalue_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"

# Keyword skipping over an error INI entry
# Pattern slippage with whitespace inside a keyword
ini_file="# comment line
[Default]FallbackDNS=14.14.14.14
[Resolve]DNS _Server1=15.15.15.15
[Gateway]Hidden_DNS_Master=16.16.16.16
"
assert_keyvalue_get "$ini_file" "" "" "" "unused keyword"
assert_keyvalue_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_keyvalue_get "$ini_file" "Default" "FallbackDNS" "14.14.14.14" "standard"
assert_keyvalue_get "$ini_file" "Resolve" "DNS" "" "incomplete but matching keyword, 'Resolve' section"
assert_keyvalue_get "$ini_file" "Resolve" "DNS_Server1" "" "incomplete but matching keyword, 'Resolve' section, NULL answer"
assert_keyvalue_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"

# Sectional skipping, heavily commented
ini_file="# comment line
[Default]FallbackDNS=17.17.17.17
[Resolve]DNS_Server1=18.18.18.18   # should NOT get this one
[Resolve]DNS=19.19.19.19   # should NOT this one 
[Resolve]DNS_Server2=20.20.20.20   # should get this one 
[Resolve]DNS=21.21.21.21   # should get this one
[Gateway]Hidden_DNS_Master=22.22.22.22
"
assert_keyvalue_get "$ini_file" "" "" "" "unused keyword"
assert_keyvalue_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_keyvalue_get "$ini_file" "Gateway" "Hidden_DNS_Master" "22.22.22.22" "unique section, underscored keyword"

assert_keyvalue_get "$ini_file" "NoSuchSection" "DNS" "" "unique section, unused keyword, noSuchSection"

# Multiple same-sectional segments
ini_file="# comment line
[Default]FallbackDNS=21.21.21.21
[Resolve]DNS_Server1=22.22.22.22
[DifferentSection]DNS=23.23.23.23
[Resolve]DNS=24.24.24.24
[Resolve]DNS_Server2=25.25.25.25
[DifferentSection2]DNS=26.26.26.26
[Resolve]DNS=27.27.27.27
[Gateway]Hidden_DNS_Master=28.28.28.28"
assert_keyvalue_get "$ini_file" "" "" "" "unused keyword"
assert_keyvalue_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"

# TBD: Looks bad here
assert_keyvalue_get "$ini_file" "Resolve" "DNS" \
	"24.24.24.24
27.27.27.27
" "keyword 2 of 2, 'Resolve' section"
assert_keyvalue_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"

# in-line comment recovery
ini_file="# comment line
[Default]FallbackDNS=30.30.30.30  # comment 1
[Resolve]DNS_Server1=31.31.31.31  ; comment 2
[DifferentSection]DNS=32.32.32.32  // comment 3
[Resolve]DNS=33.33.33.33  # comment 4
[Resolve]DNS_Server2=34.34.34.34  ; comment 5
[DifferentSection2]DNS_2=35.35.35.35  // comment 6
[Resolve]DNS=36.36.36.36  ; comment 7
;  comment 8
#  comment 9
//   comment 10
[Gateway]Hidden_DNS_Master=37.37.37.37  # comment 11
"
assert_keyvalue_get "$ini_file" "" "" "" "unused keyword"
assert_keyvalue_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_keyvalue_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"
assert_keyvalue_get "$ini_file" "Default" "FallbackDNS" "30.30.30.30" "standard"
assert_keyvalue_get "$ini_file" "Resolve" "DNS_Server1" "31.31.31.31" "standard"
assert_keyvalue_get "$ini_file" "DifferentSection" "DNS" "32.32.32.32" "standard"
assert_keyvalue_get "$ini_file" "Resolve" "DNS_Server2" "34.34.34.34" "standard"
assert_keyvalue_get "$ini_file" "DifferentSection2" "DNS_2" "35.35.35.35" "standard"

# TBD: Another one bites the dust
assert_keyvalue_get "$ini_file" "Resolve" "DNS" \
	"33.33.33.33
36.36.36.36
" "standard"

# in-line comment recovery, value are double-quoted
ini_file="# comment line
[Default]FallbackDNS=\"40.40.40.40\"  # comment 1
[Resolve]DNS_Server1=\"41.41.41.41\"  ; comment 2
[DifferentSection]DNS=\"42.42.42.42\"  // comment 3
[Resolve]DNS=\"43.43.43.43\"  # comment 4
[Resolve]DNS_Server2=\"44.44.44.44\"  ; comment 5
[DifferentSection2]DNS_2=\"45.45.45.45\"  // comment 6
[Resolve]DNS=\"46.46.46.46\"  ; comment 7
;  comment 8
#  comment 9
//   comment 10
[Gateway]Hidden_DNS_Master=\"47.47.47.47\" # comment 11
"
assert_keyvalue_get "$ini_file" "" "" "" "unused keyword"
assert_keyvalue_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_keyvalue_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"
assert_keyvalue_get "$ini_file" "Default" "FallbackDNS" "\"40.40.40.40\"" "standard"
assert_keyvalue_get "$ini_file" "Resolve" "DNS_Server1" "\"41.41.41.41\"" "standard"
assert_keyvalue_get "$ini_file" "DifferentSection" "DNS" "\"42.42.42.42\"" "standard"
assert_keyvalue_get "$ini_file" "Resolve" "DNS_Server2" "\"44.44.44.44\"" "standard"
assert_keyvalue_get "$ini_file" "DifferentSection2" "DNS_2" "\"45.45.45.45\"" "standard"

# TBD: Looks like a common theme or bug here
assert_keyvalue_get "$ini_file" "Resolve" "DNS" \
	"\"43.43.43.43\"
\"46.46.46.46\"
" "standard"
assert_keyvalue_get "$ini_file" "Gateway" "Hidden_DNS_Master" "\"47.47.47.47\"" "standard"

# comment symbols are inside double-quotes 
# (here, double-quotes should not be treated as a inline comment)
ini_file="# comment line
[Default]FallbackDNS=\"50.50#50.50\"
[Resolve]DNS_Server1=\"51.51;51.51\"
[DifferentSection]DNS=\"52.52.52.52\"
[Resolve]DNS=\"#53.53.53.53\"
[Resolve]DNS_Server2=\";54.54.54.54\"
[DifferentSection2]DNS_2=\"//55.55.55.55\"
[Resolve]DNS=\"56.56.56.56;\"
[Gateway]Hidden_DNS_Master=\"57.57.57.57#\"
[Gateway]Hidden_DNS_Master2=\"58.58.58.58//\"
"
assert_keyvalue_get "$ini_file" "" "" "" "unused keyword"
assert_keyvalue_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_keyvalue_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"
assert_keyvalue_get "$ini_file" "Default" "FallbackDNS" "\"50.50#50.50\"" "standard"
assert_keyvalue_get "$ini_file" "Resolve" "DNS_Server1" "\"51.51;51.51\"" "standard"
assert_keyvalue_get "$ini_file" "DifferentSection" "DNS" "\"52.52.52.52\"" "standard"
assert_keyvalue_get "$ini_file" "Resolve" "DNS_Server2" "\";54.54.54.54\"" "standard"
assert_keyvalue_get "$ini_file" "DifferentSection2" "DNS_2" "\"//55.55.55.55\"" "standard"

# TBD: (sigh) and thar she blow!
assert_keyvalue_get "$ini_file" "Resolve" "DNS" \
	"\"#53.53.53.53\"
\"56.56.56.56;\"
" "standard"
assert_keyvalue_get "$ini_file" "Gateway" "Hidden_DNS_Master" "\"57.57.57.57#\"" "standard"
assert_keyvalue_get "$ini_file" "Gateway" "Hidden_DNS_Master2" "\"58.58.58.58//\"" "standard"

# comment symbols are inside double-quotes 
# (here, single-quotes should not be treated as an inline comment)
ini_file="# comment line
[Default]FallbackDNS=\"60.60#60.60\"
[Resolve]DNS_Server1=\"61.61;61.61\"
[DifferentSection]DNS=\"62.62//62.62\"
[Resolve]DNS=\"#63.63.63.63\"
[Resolve]DNS_Server2=\";64.64.64.64\"
[DifferentSection2]DNS_2=\"//65.65.65.65\"
[Resolve]DNS=\"66.66.66.66;\"
[Gateway]Hidden_DNS_Master=\"67.67.67.67#\"
[Gateway]Hidden_DNS_Master2=\"68.68.68.68//\"
"
assert_keyvalue_get "$ini_file" "" "" "" "no section, no keyword"
assert_keyvalue_get "$ini_file" "" "DNS" "" "no-section, unused keyword"
assert_keyvalue_get "$ini_file" "NoSuchSection" "DNS" "" "unused section, unused keyword"
assert_keyvalue_get "$ini_file" "Default" "FallbackDNS" "\"60.60#60.60\"" "# inside double-quote"
assert_keyvalue_get "$ini_file" "Resolve" "DNS_Server1" "\"61.61;61.61\"" "; inside double-quote"
assert_keyvalue_get "$ini_file" "DifferentSection" "DNS" "\"62.62//62.62\"" "// inside double-quote"
assert_keyvalue_get "$ini_file" "Resolve" "DNS_Server2" "\";64.64.64.64\"" "; inside LHS double-quote"
assert_keyvalue_get "$ini_file" "DifferentSection2" "DNS_2" "\"//65.65.65.65\"" "// inside LHS double-quote"
assert_keyvalue_get "$ini_file" "Resolve" "DNS" \
	"\"#63.63.63.63\"
\"66.66.66.66;\"
" "; inside RHS double-quote"
assert_keyvalue_get "$ini_file" "Gateway" "Hidden_DNS_Master" "\"67.67.67.67#\"" "# inside RHS double-quote"
assert_keyvalue_get "$ini_file" "Gateway" "Hidden_DNS_Master2" "\"68.68.68.68//\"" "// inside RHS double-quote"

# comment symbols are inside AND outside single-quotes
ini_file="# comment line
[Default]FallbackDNS=\"70.70#70.70\"  # inline # inside double-quote
[Resolve]DNS_Server1=\"71.71;71.71\"  ; inline ; inside double-quote
[DifferentSection]DNS=\"72.72//72.72\"  // \"comment 3\" ; still an inline
[Resolve]DNS=\"#73.73.73.73\"  # inline # LHS double-quote
[Resolve]DNS_Server2=\";74.74.74.74\"  ; inline ; LHS double-quote
[DifferentSection2]DNS_2=\"//75.75.75.75\"  // inline '/' '/' LHS double-quote
[Resolve]DNS=\"76.76.76.76;\"  ; inline ; RHS double-quote
[Gateway]Hidden_DNS_Master=\"77.77.77.77#\"  # inline # RHS double-quote
[Gateway]Hidden_DNS_Master2=\"78.78.78.78//\"  // inline '/' '/' RHS double-quote
"
assert_keyvalue_get "$ini_file" "Default" "FallbackDNS" "\"70.70#70.70\"" "# inside double-quote and outside"
assert_keyvalue_get "$ini_file" "Resolve" "DNS_Server1" "\"71.71;71.71\"" "; inside quote and outside"

assert_keyvalue_get "$ini_file" "Resolve" "DNS_Server2" "\";74.74.74.74\"" "; inside LHS double-quote and outside"

assert_keyvalue_get "$ini_file" "Resolve" "DNS" \
	"\"#73.73.73.73\"
\"76.76.76.76;\"
" "; inside RHS double-quote and outside"
# FAILED TEST (needs to improve 'ini_file_read' REGEX)
# Obviously that a multi-state regex for '//' is needed
assert_keyvalue_get "$ini_file" "Gateway" "Hidden_DNS_Master2" "\"78.78.78.78//\"" "// inside RHS double-quote and outside"

assert_keyvalue_get "$ini_file" "DifferentSection" "DNS" "\"72.72//72.72\"" "// inside double-quote and outside"
assert_keyvalue_get "$ini_file" "DifferentSection2" "DNS_2" "\"//75.75.75.75\"" "// inside LHS double-quote and outside"

assert_keyvalue_get "$ini_file" "Gateway" "Hidden_DNS_Master" "\"77.77.77.77#\""
"# inside RHS double-quote and outside"

assert_keyvalue_get "$ini_file" "Resolve" "DNS" \
"19.19.19.19
21.21.21.21" \
       	"keyword 2 of 2 Resolve section"
echo

echo "${BASH_SOURCE[0]}: Done."

