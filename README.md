# bash-ini-file
Extract keyvalues from section/keyword from [INI-format (v1.4)](https://cloanto.com/specs/ini/#escapesequences) file in bash.

You got an INI file, I've got the bash script to get your settings from.

Works with:

* systemd configuration file
* NetworkManager configuration file
* ifup/down configuration file
* PHP configuration file
* Windows .INI

Treats no-section as '`[Default]`';  reads both sections together as one.

Also correctly finds the last keyword of the desired section before extracting its keyvalue, despite multiply-defined/multiple-reused section blocks.

Details
=======

File format: .INI
Supported version: 1.4 (2009)

Features:

* POSIX-compliant
* loads all settings into bash string (no variable array)
* Treats no-section as '`[Default]`';  reads both sections together as one.
* 30,000 keyvalue lookup per second.  (well, like performance matters anyway)

Demo
====
A nice bash script can be either my `example-usage.sh` script or below:

```bash
source bash-ini-parser.sh
raw_data="$(cat "/etc/systemd/systemd.conf" | ini_file_read
ini_kv_get "Default" "DNS"
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



