#!/bin/bash 

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $DIR/common.sh

echo  "getting device to unmount"
umount $ROOT_PART
remove_parts
