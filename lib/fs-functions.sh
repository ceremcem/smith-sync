get_free_space_of_snap () {
    # returns in KBytes
    local snap=$1
    #echo_info "Calculating free space of $(mount_point_of $snap)"
    df -k --output=avail $snap | sed '2q;d'
}

is_free_space_more_than () {
    local target_size_str=$1
    local target_size=$(echo $target_size_str | numfmt --from=si)
    target_size=$(( $target_size / 1000 ))
    local snap=$2
    local curr_size=$(get_free_space_of_snap $snap)

    echo_debug "target_size: $target_size ($target_size_str), curr_size: $curr_size"
    if (( "$curr_size" >= "$target_size" )); then
        echo_debug "Free space is enough."
        return 0
    else
        echo_debug "Free space is NOT enough..."
        return 1
    fi
}

mount_point_of () {
    local file=$1
    findmnt -n -o TARGET --target $file
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

decrypt_crypted_partition () {
    find_crypt_partition
	echo "Decrypting ${CRYPT_DEVICE}..."
	KEY=""
	if [[ "$1" != "" ]]; then
		KEY="--key-file $1"
	fi
	cryptsetup $KEY luksOpen "${CRYPT_DEVICE}" "$D_DEVICE" || echo_err "error while decrypting."
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


require_mounted () {
	if ! mountpoint $1 > /dev/null 2>&1; then
		echo_err "$1 is not a mountpoint, mount first!"
	fi
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

exec_limited () {
	cpulimit -l 30 -f -q -- $*
	return $?
}
