#!/bin/bash
set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

safe_source $DIR/../common.sh
safe_source $DIR/config.sh

start_timer

require_mounted $BACKUP_MEDIA
require_being_btrfs_subvolume $DEST_SSH_SNAP

echo_green "Started sync-physical"

SNAP_ROOT="$BACKUP_MEDIA/$SNAP_CONTAINER"
send_all_snapshots "$SNAP_ROOT/$SRC1_SUB1" "$DEST_SSH_SNAP/$SRC1_SUB1"
show_timer "sync of $SRC1_SNAP completed in"

send_all_snapshots "$SNAP_ROOT/$SRC2_SUB1" "$DEST_SSH_SNAP/$SRC2_SUB1"
show_timer "Synchronization finished in"
