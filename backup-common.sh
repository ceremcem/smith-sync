#!/bin/bash 

ROOT_NAME="zencefil" # The volume group name 
SWAP_PART="/dev/$ROOT_NAME/swap"
ROOT_PART="/dev/$ROOT_NAME/root"

ROOT_MOUNT_POINT="/mnt/${ROOT_NAME}"
D_DEVICE="${ROOT_NAME}_crypt"  # decrypted device name
D_DEVICE_PATH="/dev/mapper/$D_DEVICE"

SRC1="/mnt/erik"
SRC1_SNAP="$SRC1/snapshots"
SRC1_SUB1="rootfs"

SRC2="/mnt/heybe"
SRC2_SNAP="$SRC2/snapshots"
SRC2_SUB1="cca-heybe"

DEST="$ROOT_MOUNT_POINT"
DEST_SNAP="$DEST/snapshots"
