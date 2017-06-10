#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

require_mounted $SRC1
require_mounted $SRC2
require_mounted $DEST

require_being_btrfs_subvolume $DEST_SNAP 

echo "Syncing $SRC1_SNAP"
buttersink $SRC1_SNAP/ $DEST_SNAP || echo_err "error in syncing $SRC1_SNAP"

echo "Syncing $SRC2_SNAP"
buttersink $SRC2_SNAP/ $DEST_SNAP || echo_err "error in syncing $SRC2_SNAP"
