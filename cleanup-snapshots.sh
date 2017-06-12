#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

cleanup_snapshots_by_disk_space () {
    # usage FUNCTION 250G /path/to/src-snapshots /path/to/dest-snapshots-which-will-be-deleted
    local required_space=$1
    local SRC_SNAPSHOTS=$2
    local DEST_SNAPSHOTS=$3

    echo_green "Getting incomplete snapshots in $DEST_SNAPSHOTS"
    while read -a snap; do
        if is_snap_safe_to_del $snap $SRC_SNAPSHOTS; then
            echo "it is safe to delete $snap"
        fi
    done < <(snapshots_in --incomplete $DEST_SNAPSHOTS)

    echo_yellow "Deleting incomplete snapshots in $DEST_SNAPSHOTS"
    while read -a snap; do
        if is_snap_safe_to_del $snap $SRC_SNAPSHOTS; then
            echo "it is safe to delete $snap"
            btrfs sub delete $snap
        fi
    done < <(snapshots_in --incomplete $DEST_SNAPSHOTS)

    echo_yellow "Checking if we can delete from $DEST_SNAPSHOTS"

    while read -a snap; do
        if is_snap_safe_to_del $snap $SRC_SNAPSHOTS; then
            echo "it is safe to delete $snap"
            #wait_for_calculation="60s"
            wait_for_calculation="5s"
            echo "Sleeping for $wait_for_calculation in order to update free space..."
            sleep $wait_for_calculation
            if is_free_space_more_than $required_space $DEST_SNAPSHOTS; then
                echo "Free space is more than $required_space"
                break
            else
                echo "Free space is lower than $required_space, deleting $snap"
                breakpoint
                btrfs sub delete "$snap"
            fi
        else
            echo "IT IS NOT SAFE TO DELETE $snap"
        fi
    done < <(snapshots_in $DEST_SNAPSHOTS)
}

needed_space="200G"
echo_green "Starting cleanup to make $needed_space of free space in $(mount_point_of $DEST_SNAP)"

cleanup_snapshots_by_disk_space $needed_space "$SRC2_SNAP/$SRC2_SUB1" "$DEST_SNAP/$SRC2_SUB1"
cleanup_snapshots_by_disk_space $needed_space "$SRC1_SNAP/$SRC1_SUB1" "$DEST_SNAP/$SRC1_SUB1"

echo_green "Cleanup done, current free space: $(get_free_space_of_snap $DEST_SNAP) K"
