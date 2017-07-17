#!/bin/bash

set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

safe_source $DIR/../common.sh
safe_source $DIR/config.sh

start_timer

for i in $SRC1 $SRC2 $DEST; do
    require_mounted $i
done

require_being_btrfs_subvolume $DEST_SNAP

echo_green "Started sync-local"

send_all_snapshots "$SRC1_SNAP/$SRC1_SUB1" "$DEST_SNAP/$SRC1_SUB1"
show_timer "sync of $SRC1_SNAP completed in"

send_all_snapshots "$SRC2_SNAP/$SRC2_SUB1" "$DEST_SNAP/$SRC2_SUB1"
show_timer "Synchronization finished in"
