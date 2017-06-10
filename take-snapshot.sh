#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

# check if rollback_snapshot is mounted or not, because we don't want
# to delete a mounted snapshot
require_not_mounted $ROLLBACK_SNAPSHOT

new_rollback_snapshot=$(last_snapshot_in "$SRC1_SNAP/$SRC1_SUB1")

echo "Taking Snapshots..."
TIMESTAMP=$(get_timestamp)
btrfs sub snap -r "$SRC1/$SRC1_SUB1" "$SRC1_SNAP/$SRC1_SUB1/$SRC1_SUB1.$TIMESTAMP"
btrfs sub snap -r "$SRC2/$SRC2_SUB1" "$SRC2_SNAP/$SRC2_SUB1/$SRC2_SUB1.$TIMESTAMP"

echo "Putting last snapshot in rollback location ($ROLLBACK_SNAPSHOT)"
new_rollback_path="$SRC1_SNAP/$SRC1_SUB1/$new_rollback_snapshot"

btrfs sub delete $ROLLBACK_SNAPSHOT
btrfs sub snap $new_rollback_path $ROLLBACK_SNAPSHOT
