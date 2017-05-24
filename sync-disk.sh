#!/bin/bash 

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/backup-common.sh

require_mounted $SRC1
require_mounted $SRC2
require_mounted $DEST


if ! is_btrfs_subvolume $DEST_SNAP; then 
	echo "$DEST_SNAP not found, trying to create"
	btrfs sub create $DEST_SNAP
fi

exec_limited () {
	cpulimit -l 30 -f -q -- $* 
	return $? 
}

# ----------------------------------
#             IMPORTANT! 
# ----------------------------------
# 
# Do not use "-d" switch to delete snapshots 
# from destination which are not in source
# because as destination is same, buttersink will
# always keep only the last synchronization. 
#
# example: buttersink -d a/ sync/
#          buttersink -d b/ sync/
#
# if `a` contains `mysnap1/mysnap-*` and `b` contains `mysnap2/mysnap-*`, 
# since `b` does not contain `mysnap1` folder (or subvolume), `sync/mysnap1/*`
# will be deleted. 

echo "Syncing $SRC1_SNAP"
exec_limited buttersink $SRC1_SNAP/ $DEST_SNAP || echo_err "error in syncing $SRC1_SNAP"

echo "Syncing $SRC2_SNAP"
exec_limited buttersink $SRC2_SNAP/ $DEST_SNAP || echo_err "error in syncing $SRC2_SNAP"
#exec_limited rsync -avP /boot 
