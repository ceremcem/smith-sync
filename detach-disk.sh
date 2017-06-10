#!/bin/bash
#
# pass "--force" as first argument if you want to remove disks forcibly.
#
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

FORCE_FLAG=$1

umount_if_mounted $FORCE_FLAG $ROOT_PART
remove_lvm_parts || echo_err "Problem while removing lvm parts."
remove_crypted_part
