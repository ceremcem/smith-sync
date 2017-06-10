#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

for i in $SRC1 $SRC2 $DEST; do
    require_mounted $i
done

require_being_btrfs_subvolume $DEST_SNAP


SOURCE_SNAPS="$SRC2_SNAP/$SRC2_SUB1"
DESTINATION_SNAPS="$DEST_SNAP/$SRC2_SUB1"
echo "Sendings snapshots from $SOURCE_SNAPS to $DESTINATION_SNAPS"

while read -a src; do
    dest="$DESTINATION_SNAPS/$(basename $src)"
    echo "$src ===>>> $dest"

    get_snapshot_in_dest $src $DESTINATION_SNAPS

    echo "..."
    echo "..."
    continue
    if is_subvolume_successfully_sent $dest; then
        echo "subvol ok"
    else
        echo "subvol will be deleted"
        #btrfs sub delete $snap
    fi

done < <(snapshots_in $SOURCE_SNAPS)
