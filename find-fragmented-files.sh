#!/bin/bash
set -eu

path=$1
args=
[[ $(whoami) = "root" ]] || exec sudo "$0" "$@"
[[ ${2:-} == "--single-dev" ]] && args="-xdev"
find $path $args -type f| xargs filefrag 2>/dev/null | sed 's/^\(.*\): \([0-9]\+\) extent.*/\2 \1/' | awk -F ' ' '$1 > 50' | sort -n -r

