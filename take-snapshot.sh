#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh
start_timer

# check if rollback_snapshot is mounted or not, because we don't want
# to delete a mounted snapshot
require_not_mounted $ROLLBACK_SNAPSHOT

new_rollback_snapshot=$(last_snapshot_in "$SRC1_SNAP/$SRC1_SUB1")

echo "Taking Snapshots..."
TIMESTAMP=$(get_timestamp)
take_snapshot "$SRC1/$SRC1_SUB1" "$SRC1_SNAP/$SRC1_SUB1/$SRC1_SUB1.$TIMESTAMP"
take_snapshot "$SRC2/$SRC2_SUB1" "$SRC2_SNAP/$SRC2_SUB1/$SRC2_SUB1.$TIMESTAMP"

show_timer "All snapshots are taken."

echo "Putting last snapshot ($new_rollback_snapshot) in rollback location ($ROLLBACK_SNAPSHOT)"
mv $ROLLBACK_SNAPSHOT $ROLLBACK_SNAPSHOT.del
btrfs sub snap $new_rollback_snapshot $ROLLBACK_SNAPSHOT
btrfs sub delete $ROLLBACK_SNAPSHOT.del

show_timer "Taking snapshots process ended. "
