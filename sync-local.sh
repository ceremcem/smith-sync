#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

for i in $SRC1 $SRC2 $DEST; do
    require_mounted $i
done

require_being_btrfs_subvolume $DEST_SNAP


#SOURCE_SNAPS="$SRC1_SNAP/$SRC1_SUB1"
#DESTINATION_SNAPS="$DEST_SNAP/$SRC1_SUB1"
SOURCE_SNAPS="$SRC2_SNAP/$SRC2_SUB1"
DESTINATION_SNAPS="$DEST_SNAP/$SRC2_SUB1"
echo "Sendings snapshots from $SOURCE_SNAPS to $DESTINATION_SNAPS"
echo "===================================================================="

ref_snapshot=""
while read -a src; do
    if [[ "$(get_snapshot_in_dest $src $DESTINATION_SNAPS)" != "" ]]; then
        echo "$src exists in destination, no need to send again."
        ref_snapshot=$src
    else
        echo "$src will be sent to destination."
        # Minimum difference algorithm:
        # --------------------------------
        # since this utility is designed to send incremental backups, most
        # probably the minimum amount of difference will be optained between the
        # previous snapshot which has been successfully sent to the destination
        # and this one.

        dest_snap_path="$DESTINATION_SNAPS/$(basename $src)"
        echo "trying to rename to backup the $dest_snap_path in destination."
        mv $dest_snap_path "$dest_snap_path.backup-$(get_timestamp)" 2> /dev/null

        # over file
        if false; then
            tmp_file="/home/ceremcem/tmp/$(basename $src)"
            btrfs send -v -p $ref_snapshot -f $tmp_file $src || echo_err "Problem in btrfs send"
            btrfs receive -f $tmp_file $DESTINATION_SNAPS
            echo "DO NOT FORGET TO REMOVE $tmp_file"
        else
            # directly
            # simulating send (in order to show the total stream size)
            ####btrfs send -v -p $ref_snapshot $src | pv > /dev/null
            # actual transfer
            btrfs send -v -p $ref_snapshot $src | pv | btrfs receive $DESTINATION_SNAPS
        fi
    fi

    echo "--------------------------------------------------------------------"
    continue
    if is_subvolume_successfully_sent $dest; then
        echo "subvol ok"
    else
        echo "subvol will be deleted"
        #btrfs sub delete $snap
    fi

done < <(snapshots_in $SOURCE_SNAPS)
