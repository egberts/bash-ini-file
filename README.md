# bash-ini-file
Extract keyvalues from section/keyword from INI-format (v1.4) file in bash

You got an INI file, I've got the bash script to get your settings.

Works with:

* systemd configuration file
* NetworkManager configuration file
* ifup/down configuration file
* PHP configuration file

Treats no-section as '`[Default]`';  reads both sections together as one.

Also correctly finds the last keyword of the desired section before extracting its keyvalue, despite multiply-reused section blocks.

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
A nice bash script can be:

```bash
source bash-ini-parser.sh
my_ini="$(cat "/etc/systemd/systemd.conf" | ini_file_read
ini_kv_get "Default" "DNS"
```

Unit Test
=========
`tests` subdirectory performs the comprehensive unit test, in case you tweaked it, this will find any errors of yours.



