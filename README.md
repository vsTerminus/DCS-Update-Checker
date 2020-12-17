# DCS Update Checker

![GitHub](https://img.shields.io/github/license/vsTerminus/DCS-Update-Checker) ![GitHub release (latest by date)](https://img.shields.io/github/v/release/vsTerminus/DCS-Update-Checker)

This is a pretty simple script which just polls the DCS Updates page (https://updates.digitalcombatsimulator.com) periodically and compares the latest version on that page with the version listed in your game's autoupdate.cfg file.

If they do not match it will ding the terminal and optional post a message to a Discord webhook URL and then exit. Otherwise it will keep checking every few minutes (configurable).

## Config

Rename "config.ini.example" to "config.ini" and then fill it out as instructed inside the file. Use your favorite text editor.

## Run from source

You will need Perl and Cpanminus installed. Run `cpanm --installdeps .` to install this script's dependencies, and then `perl update-check.pl` to start the script. 

## Run from .exe

Just double click the .exe file after filling out the config.

## Build from source

Either create a config file called "windows.ini" or edit Makefile to use your config.ini instead for Windows.

```bash
cpanm --installdeps .
cpanm pp
make
```

## LICENSE

MIT

