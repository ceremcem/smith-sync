#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

# find and decrypt the crypted partition
decrypt_crypted_partition

echo "waiting for lvm to be activated..."
sleep 2
lvchange -a y $ROOT_NAME
lvscan

# create mountpoint and mount
mkdir -p $ROOT_MOUNT_POINT
mount_unless_mounted $ROOT_PART $ROOT_MOUNT_POINT
