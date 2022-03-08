Get that keyvalue from INI!

# bash-ini-file
From an [INI-format (v1.4)](https://cloanto.com/specs/ini/#escapesequences) file, be able to extract any keyvalue by its section/keyword ... in `bash`.

You got an INI file, I've got the bash script in which to get your settings from with.

Works with:

* systemd configuration file
* NetworkManager configuration file
* ifup/down configuration file
* PHP configuration file
* Windows .INI

Treats a no-section (any `keyword=keyvalue` before a `[section]`) as a '`[Default]`';  reads both no-section and `[Default]` together as `[Default]`.

Also correctly finds the last keyvalue of the desired section/keyword before extracting its keyvalue, despite its multiply-defined/multiple-reused interspersed/alternating section blocks.

HOW I DID THIS
==============

The secret sauce is to convert the entire INI file into a parsable syntax format with one `awk`:

```awk
/^\[.*\]$/{obj=$0}/=/{print obj $0}'
```
so a bash line was born:
```bash
ini_buffer="$(print "%s" "$raw_buffer" | awk '/^\[.*\]$/{obj=$0}/=/{print obj $0}')"
```

Standardized INI Table Format
--------------------------
Next is to standardize the INI to a common syntax format:
```
[section]keyword=keyvalue
```

An example INI file might look like this:
```ini
loneSetting=0

[Network]
DNS=1.1.1.1

[Default]
FirstDefaultKeyword=1

```
get turned into this:
```ini
[Default]loneSetting=0
[Network]DNS=1.1.1.1
[Default]FirstDefaultKeyword=1
```

Parsable AWK/SED/GREP Galore!
=======
With a common `[section]keyword=keyvalue`, it now becomes possible to work with INI line-records in a faster manner using `sed`, `awk` and `tail`.


How To Use bash-ini-parser
====
Simply source the lone script file: `bash-ini-parser.sh`
and start calling APIs such as:

| API | `$?` | `STDOUT` | Description |
| ---- | ---- | ---- | ---- |
| `ini_read_file` | `-` | multi-line | Converts an INI-format file content into a variable containing an INI table |
| `ini_section_name_normalize` | 0/1 | string | Normalize the section name into an acceptable form of INI-compliant name. |
| `ini_section_list` | 0/1 | string | Outputs a list of section name(s) found in the INI table |
| `ini_section_extract` | `-` | multi-line | Extract one or more INI table records having this matching 'section' name |
| `ini_keyword_name_normalize` | 0/1 | string |  Normalize the keyword name into an acceptable form of INI-compliant name. |
| `ini_keyword_valid` | 0/1 | `-` | Assert that the keyword is valid for use in a INI file. |
| `ini_keyword_list` | 0/1 | string | Outputs a list of keyword name(s) found by a specified section in INI table |
| `ini_keyword_extract` | `-` | multi-line | Extracts one or more INI records having matching keyword from an INI table |
| `ini_keyvalue_get` | `-` | multi-line | Get the key value based on given section name and keyword name (most useful with `systemd`, `NetworkManager`. |
| `ini_keyvalue_get_last` | `-` | string | Get the LAST key value encountered given a section name and a keyword name. (most useful if only interested by matched keyword for the last `keyword=keyvalue` to obtain its overridden keyvalue. |

Details
=======

File format: .INI
Supported version: 1.4 (2009)

Features:

* Supports and ignores inline comment using semicolon '`;`', hashmark '`#`'; But the double-slash '`//`' regex has been properly defined but not yet integrated as `bash` yet.  See [Issue 1](https://github.com/egberts/bash-ini-file/issues/1).
* loads all settings into bash string (no variable array)
* Treats no-section as '`[Default]`';  reads both sections together as one.
* Check the section name and keyword name for valid character set.
* Nested quotes also works alongside with inline comment (except for '//' inline comment support)
* 30,000 keyvalue lookup per second.  (well, like performance really matters here anyway)

Demo
====
A nice bash script can be either my `example-usage.sh` script or below:

```bash
source bash-ini-parser.sh
read -rd '' raw_data < <(cat "/etc/systemd/system/display-manager.service")
read -rd '' ini_service_section < <(ini_file_read "$raw_data")
ini_keyvalue_get "$ini_service_section" "Service" "ExecStart"
# outputs the keyvalue
```

Or with `example-usage.sh`, this script will try to read systemd config file and determine which Display Manager that you are using:

```console
$ bash example-usage.sh 
File    : /etc/systemd/system/display-manager.service
Keyword : ExecStart
Keyvalue: /usr/bin/sddm  # <--- your section/keyword/keyvalue answer

Came from all that below:
"[Unit]Description=Simple Desktop Display Manager
[Unit]Documentation=man:sddm(1) man:sddm.conf(5)
[Unit]Conflicts=getty@tty1.service getty@tty7.service
[Unit]After=getty@tty1.service getty@tty7.service
[Unit]After=systemd-user-sessions.service systemd-logind.service
[Unit]After=haveged.service
[Service]ExecStart=/usr/bin/sddm
[Service]Restart=always
[Service]RestartSec=1s
[Service]EnvironmentFile=-/etc/default/locale
[Install]Alias=display-manager.service"

Done.
```

Unit Test
=========
The accompanied `tests` subdirectory performs the comprehensive unit testing, in case you have decided to tweaked it to your normative scenario; hopefully, this will find any errors of yours.

To exercise the test, your modified `bash-ini-parser.sh must reside above the `tests` directory as all the unit tests will perform:

```bash
#!/bin/bash
# Title: my script file

source ../bash-ini-parser.sh

...
```

Supreme Unit Testing
---
To start the global unit test, execute:

```bash
cd tests
./test-all.sh
```
and the output is long, very long, very very long.

Selective Unit Test
---

To perform a specific unit test, for example, `ini_keyvalue_get()`, execute:

```console
$ bash test-ini-keyvalue-get.sh 
assert_keyvalue_get([Default]DNS=): pass # same keyword, 'Default' section
assert_keyvalue_get([Resolve]DNS=): pass # same keyword, 'Resolve' section
assert_keyvalue_get([Default]DNS=): pass # empty ini_file
assert_keyvalue_get([Default]DNS=): pass # new line
assert_keyvalue_get([Default]DNS=): pass # hash mark no-comment
assert_keyvalue_get([Default]DNS=): pass # semicolon no-comment
assert_keyvalue_get([Default]DNS=): pass # slash-slash no-comment
assert_keyvalue_get([Default]DNS=): pass # hash mark comment
assert_keyvalue_get([Default]DNS=): pass # semicolon comment
assert_keyvalue_get([Default]DNS=): pass # slash-slash comment
assert_keyvalue_get([NoSuchSection]DNS=): pass # same keyword, 'NoSuchSection' section
assert_keyvalue_get([]=): pass # unused keyword
assert_keyvalue_get([]DNS=): pass # unused keyword, 'no-section default
assert_keyvalue_get([Resolve]DNS=): pass # unused keyword, 'Resolve' section
assert_keyvalue_get([NoSuchSection]DNS=): pass # unused keyword, noSuchSection
assert_keyvalue_get([]=): pass # unused keyword
assert_keyvalue_get([]DNS=): pass # unused keyword, 'no-section default
assert_keyvalue_get([Resolve]DNS=): pass # unused keyword, 'Resolve' section
assert_keyvalue_get([NoSuchSection]DNS=): pass # unused keyword, noSuchSection
assert_keyvalue_get([]=): pass # unused keyword
assert_keyvalue_get([]DNS=): pass # unused keyword, 'no-section default
assert_keyvalue_get([Default]FallbackDNS=): pass # standard
assert_keyvalue_get([Resolve]DNS=): pass # incomplete but matching keyword, 'Resolve' section
assert_keyvalue_get([Resolve]DNS_Server1=): pass # incomplete but matching keyword, 'Resolve' section, NULL answer
assert_keyvalue_get([NoSuchSection]DNS=): pass # unused keyword, noSuchSection
assert_keyvalue_get([]=): pass # unused keyword
assert_keyvalue_get([]DNS=): pass # unused keyword, 'no-section default
assert_keyvalue_get([Gateway]Hidden_DNS_Master=): pass # unique section, underscored keyword
assert_keyvalue_get([NoSuchSection]DNS=): pass # unique section, unused keyword, noSuchSection
assert_keyvalue_get([]=): pass # unused keyword
assert_keyvalue_get([]DNS=): pass # unused keyword, 'no-section default
assert_keyvalue_get([Resolve]DNS=): pass # keyword 2 of 2, 'Resolve' section
assert_keyvalue_get([NoSuchSection]DNS=): pass # unused keyword, noSuchSection
assert_keyvalue_get([]=): pass # unused keyword
assert_keyvalue_get([]DNS=): pass # unused keyword, 'no-section default
assert_keyvalue_get([NoSuchSection]DNS=): pass # unused keyword, noSuchSection
assert_keyvalue_get([Default]FallbackDNS=): pass # standard
assert_keyvalue_get([Resolve]DNS_Server1=): pass # standard
assert_keyvalue_get([DifferentSection]DNS=): pass # standard
assert_keyvalue_get([Resolve]DNS_Server2=): pass # standard
assert_keyvalue_get([DifferentSection2]DNS_2=): pass # standard
assert_keyvalue_get([Resolve]DNS=): pass # standard
assert_keyvalue_get([]=): pass # unused keyword
assert_keyvalue_get([]DNS=): pass # unused keyword, 'no-section default
assert_keyvalue_get([NoSuchSection]DNS=): pass # unused keyword, noSuchSection
assert_keyvalue_get([Default]FallbackDNS=): pass # standard
assert_keyvalue_get([Resolve]DNS_Server1=): pass # standard
assert_keyvalue_get([DifferentSection]DNS=): pass # standard
assert_keyvalue_get([Resolve]DNS_Server2=): pass # standard
assert_keyvalue_get([DifferentSection2]DNS_2=): pass # standard
assert_keyvalue_get([Resolve]DNS=): pass # standard
assert_keyvalue_get([Gateway]Hidden_DNS_Master=): pass # standard
assert_keyvalue_get([]=): pass # unused keyword
assert_keyvalue_get([]DNS=): pass # unused keyword, 'no-section default
assert_keyvalue_get([NoSuchSection]DNS=): pass # unused keyword, noSuchSection
assert_keyvalue_get([Default]FallbackDNS=): pass # standard
assert_keyvalue_get([Resolve]DNS_Server1=): pass # standard
assert_keyvalue_get([DifferentSection]DNS=): pass # standard
assert_keyvalue_get([Resolve]DNS_Server2=): pass # standard
assert_keyvalue_get([DifferentSection2]DNS_2=): pass # standard
assert_keyvalue_get([Resolve]DNS=): pass # standard
assert_keyvalue_get([Gateway]Hidden_DNS_Master=): pass # standard
assert_keyvalue_get([Gateway]Hidden_DNS_Master2=): pass # standard
assert_keyvalue_get([]=): pass # no section, no keyword
assert_keyvalue_get([]DNS=): pass # no-section, unused keyword
assert_keyvalue_get([NoSuchSection]DNS=): pass # unused section, unused keyword
assert_keyvalue_get([Default]FallbackDNS=): pass # # inside double-quote
assert_keyvalue_get([Resolve]DNS_Server1=): pass # ; inside double-quote
assert_keyvalue_get([DifferentSection]DNS=): pass # // inside double-quote
assert_keyvalue_get([Resolve]DNS_Server2=): pass # ; inside LHS double-quote
assert_keyvalue_get([DifferentSection2]DNS_2=): pass # // inside LHS double-quote
assert_keyvalue_get([Resolve]DNS=): pass # ; inside RHS double-quote
assert_keyvalue_get([Gateway]Hidden_DNS_Master=): pass # # inside RHS double-quote
assert_keyvalue_get([Gateway]Hidden_DNS_Master2=): pass # // inside RHS double-quote
assert_keyvalue_get([Default]FallbackDNS=): pass # # inside double-quote and outside
assert_keyvalue_get([Resolve]DNS_Server1=): pass # ; inside quote and outside
assert_keyvalue_get([Resolve]DNS_Server2=): pass # ; inside LHS double-quote and outside
assert_keyvalue_get([Resolve]DNS=): pass # ; inside RHS double-quote and outside
assert_keyvalue_get([Gateway]Hidden_DNS_Master2=): failed # // inside RHS double-quote and outside
  expected: '"78.78.78.78//"'
  actual  : '"78.78.78.78//"  // inline '/' '/' RHS double-quote'
```




