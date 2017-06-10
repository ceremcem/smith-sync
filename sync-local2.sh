#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

for mp in $SRC1 $SRC2 $DEST; do
    require_mounted $mp
done

require_being_btrfs_subvolume $DEST_SNAP

#echo "Sendings snapshots from $SRC1_SNAP to $DEST_SNAP"

#SNAP_DIR="$SRC1_SNAP/rootfs"
SNAP_DIR="$DEST_SNAP/cca-heybe"
echo "SNAP DIR: $SNAP_DIR"

while read -a snap; do
    echo "this is snapshot to send: $snap"
    is_btrfs_subvolume_ok $snap
done < <(snapshots_in $SNAP_DIR)
