#!/bin/bash

. ../bash-ini-parser.sh

assert_section_extract() {
  local raw_file section expected note ini_buffer result
  raw_file=$1
  section=$2
  expected=$3
  note=$4
  ini_buffer="$(ini_file_read "$raw_file")"
  result="$(ini_section_extract "$ini_buffer" "$section")"
  printf "assert_section_extract('%s'): " "$section" >&2
  if [ "$result" = "$expected" ]; then
    printf "found: passed: # %s\n" "$note" >&2
  else
    printf "NOT FOUND: FAILED: # %s\n  expected: '%s'\n  result  : '%s'\n" \
           "$note" "$expected" "$result" >&2
    echo "Aborted." >&2
    exit 1
  fi
}


raw_file_read()
{
cat << DATA_EOF | cat
void=unvoided

[default]
DNS=
DNS=4.4.4.4
void=devoided

[Resolve]
DNS=0.0.0.0
void="asdf;zxcv"

[spacey se c t i o n]
Underscore_here_a_lot=123

[space_suffixed ]
space_suffixed1 =123
void=asdf # comment

[ prefixed_space]
 prefixed_space1=123

[underscore_section]
Underscore_here_a_lot=123

[Resolve]
# second Resolve section, it should continue within here and pick up newer value
DNS=1.1.1.1
FallbackDNS=

DATA_EOF
}
raw_file="$(raw_file_read)"
ini_buffer="$(ini_file_read "$raw_file")"

# assert_section_extract "$ini_buffer" "Default" "$expected" "no-section default DNS"
# assert_section_extract "$ini_buffer" "" "DNS=0.0.0.0" "no-section default DNS"
assert_section_extract "$ini_buffer" "default" "[default]DNS=
[default]DNS=4.4.4.4
[default]void=devoided" "no such 'default' section"
assert_section_extract "$ini_buffer" "Resolve" \
"[Resolve]DNS=0.0.0.0
[Resolve]void=\"asdf;zxcv\"
[Resolve]DNS=1.1.1.1
[Resolve]FallbackDNS=" "simple"

ini_buffer2="[Machine1]

app=version1


[Machine2]

app=version1

app=version2

[Machine3]

app=version1
app=version3
"
assert_section_extract "$ini_buffer2" "Machine1" "[Machine1]app=version1" "StackOverflow"
echo

ini_buffer3="[Default]A="
expected="[Default]A="
assert_section_extract "$ini_buffer3" "Default" "$expected" "Last 2 lines are blank keyvalue"

ini_buffer3="[Default]A=b
[NoSuchSection]C=D
[UnusedSection]E=F
[Default]DNS=6.6.6.6
[Default]DNS=12.12.12.12
[Default]DNS="
expected="[Default]A=b
[Default]DNS=6.6.6.6
[Default]DNS=12.12.12.12
[Default]DNS="
assert_section_extract "$ini_buffer3" "Default" "$expected" "Last 1 line are blank keyvalue"

ini_buffer3="[Default]A=b
[NoSuchSection]C=D
[UnusedSection]E=F
[Default]DNS=6.6.6.6
[Default]DNS=12.12.12.12
[Default]DNS=
[Default]DNS="
expected="[Default]A=b
[Default]DNS=6.6.6.6
[Default]DNS=12.12.12.12
[Default]DNS=
[Default]DNS="
assert_section_extract "$ini_buffer3" "Default" "$expected" "Last 2 lines are blank keyvalue"

ini_buffer4="A=
B=C
D=
A=E
[NoSuchSection]Z=
[Default]G=
[BlankSection]Y=
[Default]I=J
[SectionNull]X=
"
expected="[Default]A=
[Default]B=C
[Default]D=
[Default]A=E
[Default]G=
[Default]I=J"  # no ending blank lines

assert_section_extract "$ini_buffer4" "Default" "$expected" "4 non-section,4 default mixed, ordering test"
assert_section_extract "$ini_buffer4" "NoSuchSection" "[NoSuchSection]Z=" "1 section in mixed 'default/no-section' ordering test"

echo "${BASH_SOURCE[0]}: Done."

