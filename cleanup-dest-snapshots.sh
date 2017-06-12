#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh
start_timer

needed_space="200G"
echo_green "Starting cleanup to make $needed_space of free space in $(mount_point_of $DEST_SNAP)"

cleanup_dest_snapshots_by_disk_space $needed_space "$SRC2_SNAP/$SRC2_SUB1" "$DEST_SNAP/$SRC2_SUB1"
cleanup_dest_snapshots_by_disk_space $needed_space "$SRC1_SNAP/$SRC1_SUB1" "$DEST_SNAP/$SRC1_SUB1"

echo_green "Cleanup done, current free space: $(get_free_space_of_snap $DEST_SNAP) K"
show_timer
