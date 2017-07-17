#!/bin/bash
set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

safe_source $DIR/../common.sh
safe_source $DIR/config.sh

require_not_mounted $ROOT_MOUNT_POINT

# find and decrypt the crypted partition
decrypt_crypted_partition

echo "waiting for lvm to be activated..."
sleep 2
lvchange -a y $ROOT_NAME
lvscan

# create mountpoint and mount
mkdir -p $ROOT_MOUNT_POINT
mount_unless_mounted $ROOT_PART $ROOT_MOUNT_POINT
