#!/bin/bash
set -eu

path=$1
args=
[[ $(whoami) = "root" ]] || exec sudo "$0" "$@"
[[ ${2:-} == "--single-dev" ]] && args="-xdev"

declare -a found_dirs
last_found=
while read -r d; do
    _found=$(lsattr -d "$d" 2>/dev/null | egrep 'C[-]+\s')
    echo "examining $_found"
    if [[ $? == 0 ]]; then
        if [[ -n $last_found ]] && echo "$_found" | grep -Eq '^'$last_found; then
            echo "!!!!!!!!!!!skipping $_found"
            continue
        fi
        last_found="$_found"
        found_dirs+=("$last_found")
    fi
done <<< $(find "$path" $args -type d | LC_ALL=C sort)
echo "Found dirs:"
echo "-----------"
echo "${found_dirs[*]}"
