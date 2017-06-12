#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh
start_timer

echo_green "Cleaning up $(mount_point_of $SRC2_SNAP)"
cleanup_src_snapshots_by_disk_space "200G" "$SRC2_SNAP/$SRC2_SUB1" "$DEST_SNAP/$SRC2_SUB1"

echo_green "Cleaning up $(mount_point_of $SRC1_SNAP)"
cleanup_src_snapshots_by_disk_space "5G" "$SRC1_SNAP/$SRC1_SUB1" "$DEST_SNAP/$SRC1_SUB1"

echo_green "Cleanup done"
show_timer
