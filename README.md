# bash-ini-file
Extract any keyvalues by its section/keyword from an [INI-format (v1.4)](https://cloanto.com/specs/ini/#escapesequences) file in bash.

You got an INI file, I've got the bash script in which to get your settings from with.

Works with:

* systemd configuration file
* NetworkManager configuration file
* ifup/down configuration file
* PHP configuration file
* Windows .INI

Treats a no-section (any `keyword=keyvalue` before a `[section]`) as a '`[Default]`';  reads both no-section and `[Default]` together as `[Default]`.

Also correctly finds the last keyvalue of the desired section/keyword before extracting its keyvalue, despite its multiply-defined/multiple-reused interspersed/alternating section blocks.

How To Use bash-ini-file
====
Simply source the lone script file: `bash-ini-file.sh`
and start calling APIs such as:

| asdf | asdf | asdf |
| asdf | asdf | asdf |

Details
=======

File format: .INI
Supported version: 1.4 (2009)

Features:

* Supports and ignores inline comment using semicolon '`;`', hashmark '`#`'; But the double-slash '`//`' regex has been properly defined but not yet integrated as `bash` yet.  See Issue 1.
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
`tests` subdirectory performs the comprehensive unit test, in case you tweaked it, this will find any errors of yours.



