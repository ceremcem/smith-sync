#!/bin/bash 

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh


SRC1="/mnt/erik"
SRC1_SNAP="$SRC1/snapshots"
SRC1_SUB1="rootfs"

SRC2="/mnt/heybe"
SRC2_SNAP="$SRC2/snapshots"
SRC2_SUB1="cca-heybe"

DEST="$ROOT_MOUNT_POINT"
DEST_SNAP="$DEST/snapshots"
