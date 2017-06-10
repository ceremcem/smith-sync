#!/bin/bash

DEBUG=true

# First BTRFS source path settings
SRC1="/mnt/erik"
SRC1_SNAP="$SRC1/snapshots"
SRC1_SUB1="rootfs"

# Second BTRFS source path settings
SRC2="/mnt/heybe"
SRC2_SNAP="$SRC2/snapshots"
SRC2_SUB1="cca-heybe"

# Local USB target disk settings (/dev/disk/by-id/$KNOWN_DISK)
KNOWN_DISK="usb-WD_Elements_10A8_575833314536335946303730-0:0"

# Local USB target path settings
ROOT_NAME="zencefil" # The volume group name
SWAP_PART="/dev/$ROOT_NAME/swap"
ROOT_PART="/dev/$ROOT_NAME/root"
ROOT_MOUNT_POINT="/mnt/${ROOT_NAME}"
D_DEVICE="${ROOT_NAME}_crypt"  # decrypted device name
D_DEVICE_PATH="/dev/mapper/$D_DEVICE"
DEST="$ROOT_MOUNT_POINT"
DEST_SNAP="$DEST/snapshots"

# SSH target settings
DEST_SSH_SNAP="/mnt/aea3/snapshots"
SSH="ssh://aea3"

# TODO: ADD: Physical disk transport settings
# ...

# Rollback location.
ROLLBACK_SNAPSHOT="$SRC1/rootfs_rollback"
