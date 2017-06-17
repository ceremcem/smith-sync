#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh
start_timer

# check if rollback_snapshot is mounted or not, because we don't want
# to delete a mounted snapshot
require_not_mounted $ROLLBACK_SNAPSHOT

echo_green "Snapshotting current rootfs as rollback ($ROLLBACK_SNAPSHOT)"
mv $ROLLBACK_SNAPSHOT $ROLLBACK_SNAPSHOT.del
btrfs sub snap / $ROLLBACK_SNAPSHOT
btrfs sub delete $ROLLBACK_SNAPSHOT.del
show_timer "Current rootfs is now in rollback location."


echo_green "Taking Snapshots..."
POSTFIX=$(get_timestamp)
take_snapshot "$SRC1/$SRC1_SUB1" "$SRC1_SNAP/$SRC1_SUB1/$SRC1_SUB1.$POSTFIX"
take_snapshot "$SRC2/$SRC2_SUB1" "$SRC2_SNAP/$SRC2_SUB1/$SRC2_SUB1.$POSTFIX"
show_timer "All snapshots are taken."

show_timer "All done."
