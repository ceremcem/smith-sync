#!/bin/bash
_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
set -eu
[[ $(whoami) = "root" ]] || exec sudo "$0" "$@"

target_name="$1"
exclude_folder=$(realpath "$2")
target_snapshots="$3"

[[ -d $exclude_folder ]] || { echo "exclude folder does not exist: $exclude_folder"; exit 1; }

get_latest_ts(){
    btrfs-ls --ro "$1" \
        | grep -oE -- '[0-9]{8}T[0-9]{4}_?[0-9]?' \
        | sort -n \
        | tail -n 1
}

latest_target_timestamp=$(get_latest_ts $target_snapshots)
[[ -z $latest_target_timestamp ]] && { echo "Target timestamp can not be found. Did you mount it?"; exit 1; }
echo "Latest snapshot on the target is excluded from cleanup: $latest_target_timestamp"

echo "$latest_target_timestamp" > ${exclude_folder}/${target_name}
