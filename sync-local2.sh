#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

for mp in $SRC1 $SRC2 $DEST; do
    require_mounted $mp
done

require_being_btrfs_subvolume $DEST_SNAP

echo "Sendings snapshots from $SRC1_SNAP to $DEST_SNAP"

while read -a snap; do
    echo "this is snapshot to send: $snap"
done < <(snapshots_in $SRC1_SNAP)
