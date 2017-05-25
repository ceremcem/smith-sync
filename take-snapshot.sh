#!/bin/bash 

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

TIMESTAMP=$(get_timestamp)
btrfs sub snap -r "$SRC1/$SRC1_SUB1" "$SRC1_SNAP/$SRC1_SUB1/$SRC1_SUB1.$TIMESTAMP"
btrfs sub snap -r "$SRC2/$SRC2_SUB1" "$SRC2_SNAP/$SRC2_SUB1/$SRC2_SUB1.$TIMESTAMP"
