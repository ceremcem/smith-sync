#!/bin/bash 

if [[ $(id -u) > 0 ]]; then 
    echo "This script needs root privileges..."
    sudo $0
    exit
fi 

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/backup-common.sh


echo_err () {
	echo "ERROR:"
	echo "ERROR:"
	echo "ERROR: $* "
	echo "ERROR:"
	echo "ERROR:"
	exit 1
}


detect_local () {

	CRYPT_PART_UUID=$(cat $DIR/crypt-part-uuid.txt)
	CRYPT_DEVICE=$(findfs UUID=$CRYPT_PART_UUID)

	if [[ ! -b $CRYPT_DEVICE ]]; then 
		echo_err "can not find disk with UUID of $CRYPT_PART_UUID"
	fi 
}

select_device () {
	DEVICE=$(readlink -e /dev/disk/by-id/$(cat $DIR/known-disk.txt))

	read -a OK_TO_GOO -p "is $DEVICE correct device? (yes/no)"
	if [[ "${OK_TO_GOO}" == "yes" ]]; then
		echo "$DEVICE selected"
	else
		echo "cancelled!"
		exit 0
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


decrypt_partition () {
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
