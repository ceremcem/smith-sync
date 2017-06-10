#!/bin/bash

if [[ $(id -u) > 0 ]]; then
    #echo "This script needs root privileges..."
    sudo $0 "$@"
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

echo_debug () {
	echo -e "DEBUG: $*\n"
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

remove_lvm_parts () {
    for lvm_part in swap root; do
        p="/dev/$ROOT_NAME/$lvm_part"
        echo "Removing LVM part: $p";
	    lvchange -a n $p || return 1
    done
}

remove_crypted_part () {
    cryptsetup luksClose "$D_DEVICE_PATH" || return 1
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

snapshots_in () {
    local TARGET=$1
    while read -a file; do
        if is_btrfs_subvolume $file; then
            echo $file
        fi
    done < <( find $TARGET -maxdepth 1 )
}

last_snapshot_in () {
    local TARGET=$1
    snapshots_in $TARGET | tail -n 1
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

umount_if_mounted () {
    local force=$1
    local flag=""
    local device=""
    if [[ "$force" == "--force" ]]; then
        flag=" -l "
        device=$2
        echo "umounting $device forcibly..."
    else
        device=$1
        echo "umounting $device..."
    fi
    umount $flag $device 2> /dev/null
}

send_snapshots () {
    local src=$1
    local dest=$2
    echo "first detect which snapshots to be sent"
}

is_btrfs_subvolume_ok () {
    local subvol=$1
    if [[ "$(get_btrfs_received_uuid $subvol)" == "-" ]]; then
        echo "$subvol is NOT OK!"
        return 1
    else
        echo "$subvol is OK.."
        return 0
    fi
}

get_btrfs_received_uuid () {
    local subvol=$1
    btrfs sub show $subvol | grep "Received UUID:" | awk -F: '{print $2}' | sed -e "s/\s//g"
}

fingerprint_of_snapshot () {
    local snap=$1
    echo "TODO: get fingerprint (uuid) of a given snapshot."
}
