#!/bin/bash
# File: section-regex.sh
# Title: Parse and find keyvalue in the .INI-format v1.4 file
#

echoerr() { printf "%s\n" "$*" >&2; }

dump_string_char()
{
  local string len_str idx this_char this_int
  string="$1"
  len_str="${#string}"
  idx=0
  while [ $idx -lt ${len_str} ]; do
    this_char="${string:$idx:1}"
    this_int="$(LC_CTYPE=C printf "%d" "'$this_char")"
    printf "idx %s: " "$idx" >&2
    if [ $this_int -lt 32 ]; then
      printf "%d\n" "${this_int}" >&2
    else
      printf "'%c'\n" "\'${this_char}\'" >&2
    fi
    ((idx++))
  done
}


# Converts an INI-format file content into a variable containing an INI table
#
# Reads a multi-line string containing original INI-format content
# and converts into an internal INI table containing multi-line
# non-array string whose line-record consists of a
# '[section_name]keyword_name=keyvalue_content' format.
#
# Syntax: ini_file_read <raw_buffer>
#     raw_buffer - a multi-line string variable 
#                  containing INI-format content
# return: (none)
# stdin:  (none)
# stdout: a multi-line string containing the condensed normalized 
#         INI-format line-record.
#         It is formatted in bracket-nested "[section]keyword=keyvalue"
# stderr: (none)
ini_file_read()
{
  local ini_buffer raw_buffer hidden_default
  raw_buffer="$1"
  # somebody has to remove the 'inline' comment
  # Currently does not do nested-quotes within a pair of same single/double
  # quote ... YET:
  #
  # But there is a way, the Regex way that works.
  #
  # Need to find a way to translate this Python regex:
  #
  # (((\x27[ \!\"\#\$\%\&\(\)\*\+\-\.\/0-9\:\;\<\=\>\?@A-Z\[\\\]\^\_\`a-z\|\~]*\x27\s*)|(\"[ \!\#\$\%\&\x27\(\)\*\+\-\.\/0-9\:\;\<\=\>\?@A-Z\[\\\]\^\_\`a-z\|\~]*\"\s*)|(\/([ \!\$\%\&\(\)\*\+\-\.0-9\:\<\=\>\?@A-Z\[\]\^\_\`a-z\|\~]+[ \!\$\%\&\(\)\*\+\-\.0-9\:\<\=\>\?@A-Z\[\]\^\_\`a-z\|\~]*)|([ \!\$\%\&\(\)\*\+\-\.0-9\:\<\=\>\?@A-Z\[\]\^\_\`a-z\|\~]*))*)*)([;#]+)*.*$
  #
  # into a bash version ... in HERE!
  #
  # Above works in https://www.debuggex.com/
  # Tested in https://extendsclass.com/regex-tester.html#pcre
  # Tested in https://www.freeformatter.com/regex-tester.html
  # Tested in https://regexr.com/
  # 
  # 
  raw_buffer="$(printf "%s" "$raw_buffer" | sed '
  s|[[:blank:]]*//.*||; # remove //comments
  s|[[:blank:]]*#.*||; # remove #comments
  t prune
  b
  :prune
  /./!d; # remove empty lines, but only those that
         # become empty as a result of comment stripping'
 )"

# awk does the removal of leading and trailing spaces
  ini_buffer="$(echo "$raw_buffer" | awk '/^\[.*\]$/{obj=$0}/=/{print obj $0}')"
  #shellcheck disable=SC2001
  ini_buffer="$(echo "$ini_buffer" | sed  's/^\s*\[\s*/\[/')"
  #shellcheck disable=SC2001
  ini_buffer="$(echo "$ini_buffer" | sed  's/\s*\]\s*/\]/')"

  # finds all 'no-section' and inserts '[Default]'
  hidden_default="$(echo "$ini_buffer" \
	          | grep -E '^[-0-9A-Za-z_\$\.]+=' | sed 's/^/[Default]/')"
  if [ -n "$hidden_default" ]; then
    echo "$hidden_default"
  fi
  # finds sectional and outputs as-is
  #shellcheck disable=SC2005
  echo "$(echo "$ini_buffer" | grep -E '^\[\s*[-0-9A-Za-z_\$\.]+\s*\]')"
}


# Normalize the section name into an acceptable form of INI-compliant name.
#
# Syntax: ini_section_name_normalize <section_name>
#   section_name - section name to transform into an 
#                  acceptable variant based on 
#                  INI-format v1.4 character set.  
# Return: 0, if unchanged; 1, if changed
# STDIN:  (none)
# STDOUT: a transformed section name that complies with INI-format v1.4
# STDERR: (none)
ini_section_name_normalize()
{
  local section result
  section="$1"
  # result="${1#"${1%%[![:space:]]*}"}"
  # result="${1#"${1%%[[:print:]]*}"}"
  # result="$(echo "$section" | sed 's/[[:space:]]//g')"
  result="$(printf "%s" "$section" | sed -e 's/[\007\\]//g')"
  result="$(printf "%s" "$section" | sed -e 's/[^-0-9a-zA-Z_\$\.]//g')"
  # result="${result%"${result##*[![:space:]]}"}"
  printf "%s" "$result"
  if [ "$1" = "$result" ]; then
    return 1
  else
    return 0
  fi
}


#
# Outputs a list of section name(s) found in the INI table
#
# Syntax: ini_section_list <ini_buffer>
#   ini_buffer - a non-array multi-line string variable
#
# Return: 0, if invalid; 1, if valid
# stdin:  (none)
# stdout: a string with no newline containing a list 
#         of sections found in the INI table.
# stderr: (none)
ini_section_list()
{
  local ini_buffer section_names 
  ini_buffer="$1"

  # extract all lines having matching section name
  # section_content is now always defined at this point ('default' or otherwise)
  section_names="$(echo "$ini_buffer" \
                 | grep '^\s*\[' \
		 | awk '{ sub(/.*\[/, ""); sub(/\].*/, ""); print }')"
  section_names="$( echo "$section_names" | sort -u | xargs )"
  echo "$section_names"
}


# Extract one or more INI table records having this matching 'section' name
# Useful for drilling down to specific section during searches of keyword(s)
#
# Syntax: ini_section_extract <ini_buffer> <section_name>
#   ini_buffer - a non-array string list variable
#   section_name - a section name, unnormalized
# return: (none)
# stdin:  (none)
# stdout: a multi-line string value consists of selected lines
#         having matched section name from a given INI table
# stderr: (none)
ini_section_extract()
{
  local section_name ini_buffer section_name
  local result normalized_section_name
  # $1 - ini_buffer
  # $2 - section name
  # extract all lines having matching section name
  ini_buffer="$1"
  section_name="$2"
  normalized_section_name="$(ini_section_name_normalize "$section_name")"
  # echoerr "ini_section_extract: new section name: $normalized_section_name"
  result="$(printf "%s" "$ini_buffer" | grep -E -- "^\[${normalized_section_name}\]")"
  printf "%s" "${result}"
}


# Test if there are any INI table record for a given 'section' name
#
# Syntax: ini_section_test <ini_buffer> <section_name>
#     ini_buffer - a non-array string list variable
#     section_name - an unnormalized section name
# return: an integer 1 if there is content having a 
#         multi-line string value consists of selected lines
#         having matched section name from a given ini_buffer
# return: $?  1 or 0
# stdin:  (none)
# stdout: (none)
# stderr: (none)
ini_section_test()
{
  local result
  result="$(ini_section_extract "$1" "$2")"
  if [ -n "$result" ]; then
    return 1
  else
    return 0
  fi
}


# Normalize the keyword name into an acceptable form of INI-compliant name.
#
# Syntax: ini_keyword_name_normalize <keyword>
#   keyword - the keyword name to normalized into an 
#             acceptable variant based on 
#             INI-format v1.4 character set.  
#             Contains a string with no newline.
#
# Return: 0, if unchanged; 1, if changed
# stdin:  (none)
# stdout: a transformed keyword name that complies with INI-format v1.4
# stderr: (none)
ini_keyword_name_normalize()
{
  local keyword sanitized_kw
  keyword="$1"
  # knock out any and all whitespaces
  sanitized_kw="$(echo "$keyword" | sed -- 's/[ \t]//g')"
  sanitized_kw="$(echo "$sanitized_kw" \
	  | sed -- 's/[\~\`\!\@\%\^\*()+=,]//g')"
  # remove pesky hash mark symbol (interferes with bash regex)
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\#]//g')"
  # remove pesky backslash (interferes with bash regex)
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\\]//g')"
  # remove pesky brackets (interferes with bash regex)
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\[]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[]]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\{]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\}]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[>]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[<]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\/]//g')"
  # remove pesky tilde (interferes with bash regex)
  # now only allow alphanum, '-', '_', '$' in keyword
  # sanitized_kw="${sanitized_kw//[^[-A-Za-z0-9_\$.]]/}"
  echo "$sanitized_kw"
}


# Assert that the keyword is valid for use in a INI file.
#
# Syntax: ini_keyword_valid <keyword>
#
#   keyword - the keyword name to normalized into an 
#             acceptable variant based on 
#             INI-format v1.4 character set.  
#             Contains a string with no newline.
#
# Return: 0, if invalid; 1, if valid
# stdin:  (none)
# stdout: (none)
# stderr: (none)
ini_keyword_valid()
{
  local keyword sanitized_kw
  keyword="$1"
  sanitized_kw="$(ini_keyword_name_normalize "$keyword")"
  if [ "$sanitized_kw" == "$keyword" ]; then
    return 1
  else
    return 0
  fi
}

#
# Outputs a list of keyword name(s) found by a specified section in INI table
#
# Syntax: ini_keyword_list <ini_buffer> <section_name>
#   ini_buffer - a non-array multi-line string variable
#   section_name - the section name in which to look for any keywords
#
# Return: 0, if invalid; 1, if valid
# stdin:  (none)
# stdout: a string with no newline containing a list 
#         of sections found in the INI table.
# stderr: (none)
ini_keyword_list()
{
  local ini_buffer section_name ini_buf_by_section keyword_names 
  ini_buffer="$1"
  section_name="$2"

  # extract all lines having the matching section name
  IFS= read -rd '' ini_buf_by_section < <(ini_section_extract "$ini_buffer" "$section_name")

  # section_content is now always defined at this point ('default' or otherwise)
  keyword_names="$(echo "$ini_buf_by_section" \
                 | grep '^\s*\[\S*\]' \
		 | awk '{ sub(/.*\]/, ""); sub(/=.*/, ""); print }')"
  keyword_names="$( echo "$keyword_names" | sort -u | xargs )"
  echo "$keyword_names"
}

# Extracts one or more INI records having matching keyword from an INI table
#
# NOTE: Useful if already called ini_section_extract 
#       and have sectional-specific table
#
# Syntax: ini_keyword_extract <ini-by-section> <keyword>
#     ini_buf_by_section - a non-array string list variable
#     keyword - a keyword name (normalized)
# return: (none)
# stdin:  (none)
# stdout: multiple lines of matching keywords (regardless of section match)
# stderr: (none)
ini_keyword_extract()
{
  local ini_by_section keyword_name
  local kvs
  local uncommented1_kvs uncommented2_kvs uncommented3_kvs lhs_despace_kvs rhs_despace_kvs
  # $1 - ini_buf_by_section
  # $2 - keyword name (normalized)

  ini_by_section="$1"
  keyword_name="$2"

  # We are going to assume that the ini-buffer is all section-alike.
  kvs="$(printf "%s" "$ini_by_section" \
	  | grep -E "^\[\S+\]\s*${keyword_name}\s*=" )"

  # before we reduce to a NULL keyvalue, remove those inline comments
  # for now, do simple removal of inline comment
  uncommented1_kvs="$(echo "$kvs" | sed "/^\s*;/d;s/\s*;[^\"']*$//")"
#  echo "ike: uncommented1_kv: \"$uncommented1_kv\""

  uncommented2_kvs="$(echo "$uncommented1_kvs" | sed "/^\s*#/d;s/\s*#[^\"']*$//")"
#  echo "ike: uncommented2_kv: \"$uncommented2_kv\""

  uncommented3_kvs="$(echo "$uncommented2_kvs" | sed "/^\s*\/\//d;s/\s*\/\/[^\"']*$//")"
#  echo "ike: uncommented3_kv: \"$uncommented3_kv\""

  # remove RHS whitespaces
  rhs_despace_kvs="$(echo "$uncommented3_kvs" | sed -- 's/\s*$//')"

  # Strip off the '[section]keyword=' part ... now
 # IFS= read -rd '' ws_kv < <(awk -F= 'NF == 2 {print $2}' <<< "$rhs_despace_kvs")

  # now delve into removal of LHS whitespaces
  lhs_despace_kvs="$(echo "$rhs_despace_kvs" | sed -- 's/^\s*//gm')"

  printf "%s" "$lhs_despace_kvs"
}


# Get the key value based on given section name and keyword name
# Syntax: ini_keyvalue_get <ini_buffer> <section_name> <keyword>
#     ini_buf_by_section - a non-array string list variable
#     section - a section name (normalized)
#     keyword - a keyword name (normalized)
# return: (none)
# stdin:  (none)
# stdout: one or more keyvalues, in output order of sequential reading
# stderr: (none)
ini_keyvalue_get()
{
  local ini_buffer section keyword
  local ini_by_section found_keylines kv final_kv
  ini_buffer="$1"
  section="$2"
  keyword="$3"

  # validate the keyword
  ini_keyword_valid "$keyword"

  # get all INI table rows by matching section name
  IFS= read -rd '' ini_by_section < <(ini_section_extract "$ini_buffer" "$section")

  # get all INI table rows by matching keyword
  # (NULL-newline handling ALERT; this bash statement is using
  # process-substitution here
  IFS= read -rd '' found_keylines < <(ini_keyword_extract "$ini_by_section" "$keyword")

  # remove inline comments
  # into BASH, for now, do simple removal of inline comment
  kv="$(echo "$found_keylines" | sed "/^\s*;/d;s/\s*;[^\"']*$//")"
  kv="$(echo "$kv" | sed "/^\s*#/d;s/\s*#[^\"']*$//")"
  kv="$(echo "$kv" | sed "/^\s*\/\//d;s/\s*\/\/[^\"']*$//")"

  # remove surrounding whitespaces
  kv="$(echo "$kv" | sed -- 's/^\s*//')"
#  kv="$(echo "$kv" | sed -- 's/\s*$//')"

  # printf "ikvg: kv: '%s'\n" "$kv" >&2
  # Remove '[section]keyword='
  IFS= read -rd '' final_kv < <(awk -F= 'RS= NF == 2 {print $2}' <<< "$kv")
  if [ "${#final_kv}" -ge 1 ]; then
    final_kv="${final_kv:0: -1}"
  fi
  # printf "ikvg: fkv: '%s'\n" "$final_kv" >&2

  printf "%s" "$final_kv"
}


# Syntax: ini_keyvalue_get_last <ini_buffer> <section_name> <keyword>
# outputs the keyvalue of its last matching section/keyword
ini_keyvalue_get_last()
{
  local ini_buffer section keyword
  local ini_by_section found_keylines kv final_kv
  ini_buffer="$1"
  section="$2"
  keyword="$3"

  # validate the keyword
  ini_keyword_valid "$keyword"

  # get all INI table rows by matching section name
  IFS= read -rd '' ini_by_section < <(ini_section_extract "$ini_buffer" "$section")

  # get all INI table rows by matching keyword
  # (NULL-newline handling ALERT; this bash statement is using
  # process-substitution here
  IFS= read -rd '' found_keylines < <(ini_keyword_extract "$ini_by_section" "$keyword")

  # only save the last updated keyvalue (the last line)
  read -rd '' kv < <(printf "%s" "$found_keylines" | tail -n1)

  # remove inline comments
  # into BASH, for now, do simple removal of inline comment
  # kv="$(echo "$kv" | sed "/^\s*;/d;s/\s*;[^\"']*$//")"
  # kv="$(echo "$kv" | sed "/^\s*#/d;s/\s*#[^\"']*$//")"
  # kv="$(echo "$kv" | sed "/^\s*\/\//d;s/\s*\/\/[^\"']*$//")"

  # remove surrounding whitespaces
  # kv="$(echo "$kv" | sed -- 's/^\s*//')"
#  kv="$(echo "$kv" | sed -- 's/\s*$//')"

  # Remove '[section]keyword='
  IFS= read -rd '' final_kv < <(awk -F= 'NF == 2 {print $2}' <<< "$kv")

  printf "%s" "$final_kv"
}



# Check if a specified keyword exist in the INI table
#
# Syntax: ini_kw_test <ini_buffer> <section_name> <keyword>
#   ini_buffer -
#   section_name - the section name in which to limit 
#                  to within this search for this 
#                  specified keyword.
#   keyword - the name of the key in which to check 
#             whether it exists in the INI table.
# return: $?  1 or 0
# stdin:  (none)
# stdout: (none)
# stderr: (none)
ini_key_test()
{
  return [ -n "$(ini_kw_get_last "$1" "$2" "$3" >/dev/null 2>&1)" ]
}

