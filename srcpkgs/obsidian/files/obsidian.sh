#!/bin/sh
export ELECTRON_IS_DEV=0
exec electron35 /usr/lib/obsidian/app.asar "$@"
