#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh


THE_SRC="/mnt/heybe/snapshots/cca-heybe"
MY_SAFE_DEL_SNAP="/mnt/zencefil/snapshots/cca-heybe/cca-heybe.20170524T0618"

# no safe because at the same location
MY_NO_SAFE_DEL_SNAP1="/mnt/heybe/snapshots/cca-heybe/cca-heybe.20170524T0618"

THE_SNAP_TO_DEL=$MY_SAFE_DEL_SNAP


is_snap_safe_to_del $THE_SNAP_TO_DEL $THE_SRC
