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

require_mounted $SRC1
require_mounted $SRC2
require_mounted $DEST

TIMESTAMP=$(get_timestamp)
btrfs sub snap -r "$SRC1/$SRC1_SUB1" "$SRC1_SNAP/$SRC1_SUB1/$SRC1_SUB1.$TIMESTAMP"
btrfs sub snap -r "$SRC2/$SRC2_SUB1" "$SRC2_SNAP/$SRC2_SUB1/$SRC2_SUB1.$TIMESTAMP"

if ! is_btrfs_subvolume $DEST_SNAP; then 
	echo "$DEST_SNAP not found, trying to create"
	btrfs sub create $DEST_SNAP
fi

buttersink $SRC1_SNAP/ $DEST_SNAP
buttersink $SRC2_SNAP/ $DEST_SNAP
