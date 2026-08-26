# MyLast - last.sh
Linux shell script that emulates the behavior of the `last` command.

> **Note:** This repository contains `last.sh`, which I developed as part of a team project. The full project (which includes `lastb.sh` for failed login attempts) can be found in the [Original Team Repository](https://github.com/Eliza-Rebeca/ProiectITBI).

## Overview
`last.sh` is a Linux shell script that emulates the standard `last` command by displaying successful login sessions from system logs.

## Supported Flags

The script supports the following options:

* `-n <number>`
  Limit the output to the first **n** entries.

* `-s <time>`
  Show sessions starting **since** the specified time or date.

* `-t <time>`
  Show sessions **until** the specified time or date.

* `-p <present>`
  Show sessions that were present at the specified time.

Flags can be combined depending on the script logic. All dates should be formatted YYYY-MM-DD.

## Usage


sh 
```
./last.sh [options][user]
```

### Examples


sh
```
./last.sh -n 5
./last.sh -s 2025-01-01
./last.sh -t 2025-01-31 12:00:00
./last.sh -p 2025-09-10 12:00:00
./last.sh alice
```


## Requirements

* Linux operating system
* Bash shell 
* Access to system login records (such as /var/log/auth.log[1-4])
