#!/bin/bash

if [[ $(id -u) > 0 ]]; then
    echo "This script needs root privileges..."
    sudo $0
    exit
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/config.sh


echo_err () {
	echo "ERROR:"
	echo "ERROR:"
	echo "ERROR: $* "
	echo "ERROR:"
	echo "ERROR:"
	exit 1
}


get_device () {
	DEVICE=$(readlink -e /dev/disk/by-id/$KNOWN_DISK)
    if [[ ! -b $DEVICE ]]; then
        echo_err "$KNOWN_DISK can not be found."
    fi
}

find_crypt_partition () {
	get_device
    CRYPT_DEVICE=$(blkid | grep $DEVICE | grep crypto_LUKS | awk '{print $1}' | sed -e 's/://g')
    if [[ ! -b $CRYPT_DEVICE ]]; then
        echo_err "crypto_LUKS partition can not be found on $DEVICE."
    fi
}

get_timestamp () {
	date +%Y%m%dT%H%M
}

is_btrfs_subvolume() {
    btrfs subvolume show "$1" >/dev/null 2>&1
}


require_mounted () {
	if ! mountpoint $1 > /dev/null 2>&1; then
		echo_err "$1 is not a mountpoint, mount first!"
	fi
}

decrypt_crypted_partition () {
    find_crypt_partition
	echo "Decrypting ${CRYPT_DEVICE}..."
	KEY=""
	if [[ "$1" != "" ]]; then
		KEY="--key-file $1"
	fi
	cryptsetup $KEY luksOpen "${CRYPT_DEVICE}" "$D_DEVICE"
}

remove_parts () {
	echo "Removing parts..."
	lvchange -a n "/dev/$ROOT_NAME/swap"
	lvchange -a n "/dev/$ROOT_NAME/root"
	cryptsetup luksClose "$D_DEVICE_PATH"
}

exec_limited () {
	cpulimit -l 30 -f -q -- $*
	return $?
}

require_being_btrfs_subvolume () {
    local subvol=$1
    if ! is_btrfs_subvolume $subvol; then
    	echo_err "$subvol not found, create it first."
    fi
}

debug_step () {
    if $DEBUG; then
        read -p "Reached debug step. Press enter to continue..."
    fi
}

last_snapshot_in () {
    local TARGET=$1
    local ALL_SNAPSHOTS_IN_PARTITION=$(btrfs sub list $TARGET | awk '{print $9}')
    local ALL_FILES=$(ls $TARGET)
    local ALL_SNAPSHOTS=""
    for file in $ALL_FILES; do
        for snap in $ALL_SNAPSHOTS_IN_PARTITION; do
            if [[ "$file" == "$snap" ]]; then
                ALL_SNAPSHOTS="$ALL_SNAPSHOTS $file"
            fi
        done
    done
    echo $ALL_SNAPSHOTS | awk '{print $NF}'
}

require_not_mounted () {
    local target=$(basename $1)
    mount | grep $target > /dev/null
    local ret=$?
    if [ $ret == 0 ]; then
        echo_err "$target IS NOT EXPECTED TO BE MOUNTED!"
    fi
}

mount_unless_mounted () {
    # mount_if_not_mounted DEVICE MOUNT_POINT
    grep -qs $2 /proc/mounts
    [ $? -ne 0 ] && mount -v "$1" "$2"
}
