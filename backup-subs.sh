#!/bin/bash
set -eu

# Description: 
# Backups all snapshots with the same directory structure into the destination folder.
#
# Usage: 
# $0 /path/to/snapshot-that-has-snapshots-in-it /path/to/backup/dir

mnt=$(./btrfs-mountpoint $1)
dest=$2

[[ "$mnt" == $(./btrfs-mountpoint $dest) ]] || { echo "Destination should be on the same disk."; exit 1; }

shopt -s lastpipe; set +m; # CAUTION: This might make the `while` loop interfere with the previous code
no_subvolume_found=true
./btrfs-ls $1 | while read i; do
    no_subvolume_found=false
    rel="${i#$mnt/}"
    target=$dest/$(dirname $rel)
    [[ -d $target ]] || sudo mkdir -p $target
    sudo btrfs sub snap $i $target/$(basename $i).rw;
done

[[ "$no_subvolume_found" == true ]] && { echo "No subvolume found. Doing nothing."; exit 0; }
