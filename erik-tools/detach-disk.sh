#!/bin/bash
#
# pass "-f" as first argument if you want to remove disks forcibly.
#
set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }; set_dir
safe_source () { source $1; set_dir; }


safe_source $DIR/config.sh
safe_source $DIR/../common.sh

FORCE_FLAG=$1

umount_if_mounted2 $ROOT_PART $FORCE_FLAG
remove_lvm_parts || echo_err "Problem while removing lvm parts."
remove_crypted_part
