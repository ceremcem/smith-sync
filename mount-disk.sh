#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

# selecting device 
detect_local
decrypt_partition

# create mountpoint
mkdir -p $ROOT_MOUNT_POINT

echo "waiting for lvm to be activated..."
sleep 2
lvscan 

echo "mounting $ROOT_PART to $ROOT_MOUNT_POINT"
mount $ROOT_PART $ROOT_MOUNT_POINT
