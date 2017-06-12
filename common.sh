#!/bin/bash

if [[ $(id -u) > 0 ]]; then
    #echo "This script needs root privileges..."
    sudo $0 "$@"
    exit
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/config.sh

DEBUG=false

echo_err () {
	>&2 echo "ERROR:"
	>&2 echo "ERROR:"
	>&2 echo "ERROR: $* "
	>&2 echo "ERROR:"
	>&2 echo "ERROR:"
	exit 1
}

echo_info () {
	echo "INFO:"
	echo "INFO: $* "
	echo "INFO:"
}

echo_debug () {
    if $DEBUG; then
        >&2 echo -e "DEBUG: $*"
    fi
}

echo_cont ()  {
    echo -ne "$*"
}

# http://webhome.csc.uvic.ca/~sae/seng265/fall04/tips/s265s047-tips/bash-using-colors.html

echo_green () {
    echo -e "\e[1;32m$*\e[0m"
}

echo_blue () {
    echo -e "\e[1;34m$*\e[0m"
}

echo_yellow () {
    echo -e "\e[1;33m$*\e[0m"
}
echo_red () {
    echo -e "\e[1;31m$*\e[0m"
}



prompt_yes_no () {
    local message=$1
    local OK_TO_CONTINUE="no"
    echo "----------------------  YES / NO  ----------------------"
    while :; do
        read -a OK_TO_CONTINUE -p "$message (yes/no) "
        if [[ "${OK_TO_CONTINUE}" == "no" ]]; then
            return 1
        elif [[ "${OK_TO_CONTINUE}" == "yes" ]]; then
            return 0
        fi
        echo "Please type 'yes' or 'no' (you said: $OK_TO_CONTINUE)"
        sleep 1
    done
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
    local subvol=$1
    btrfs subvolume show "$subvol" >/dev/null 2>&1
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

breakpoint () {
    echo -en "Reached debug step. Press enter to continue..."
    read hello </dev/tty
}

snapshots_in () {
    # usage: FUNC [options] directory
    # --all         : list all subvolumes, not only readonly ones
    # --incomplete  : list only incomplete snapshots ()
    local list_only_readonly=true
    local list_only_incomplete=false
    local TARGET=$1
    if [[ "$1" == "--all" ]]; then
        TARGET=$2
        list_only_readonly=false
    elif [[ "$1" == "--incomplete" ]]; then
        TARGET=$2
        list_only_readonly=false
        list_only_incomplete=true
    fi

    while read -a snap; do
        if is_btrfs_subvolume $snap; then
            if $list_only_readonly; then
                if is_subvolume_readonly $snap; then
                    echo $snap
                fi
            else
                if $list_only_incomplete; then
                    if is_subvolume_incomplete $snap; then
                        echo $snap
                    fi
                else
                    echo $snap
                fi
            fi
        fi
    done < <( find $TARGET/ -maxdepth 1 -mindepth 1 )
}

is_subvolume_incomplete () {
    local subvol=$1
    #DEBUG=true
    if [[ "$(get_btrfs_received_uuid $subvol)" == "" ]]; then
        echo_debug "$subvol is incomplete"
        return 0
    else
        echo_debug "$subvol is complete"
        return 1
    fi
    #DEBUG=false
}

is_subvolume_readonly () {
    local subvol=$1
    local readonly_flag="$(btrfs property get $subvol ro | grep ro= | awk -F= '{print $2}')"
    if [[ "$readonly_flag" == "true" ]]; then
        # yes, it is readonly
        return 0
    elif [[ "$readonly_flag" == "false" ]]; then
        # no, it is writable
        return 1
    else
        echo_err "${FUNCNAME[0]} can not determine if subvol is readonly or not!"
    fi
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

is_subvolume_successfully_sent () {
    local subvol=$1


    echo "TODO: what if $subvol is not a subvolume?"


    if [[ "$(get_btrfs_received_uuid $subvol)" == "-" ]]; then
        #echo "$subvol is NOT OK!"
        return 1
    else
        #echo "$subvol is OK.."
        return 0
    fi
}

get_snapshot_in_dest () {
    # get_snapshot_in_dest snapshot remote_folder
    local src=$1
    local dest=$2
    local snap_found=""
    if [[ "$2" == "" ]]; then
        echo_err "Usage: ${FUNCNAME[0]} src dest"
    fi

    #DEBUG=true


    #echo_debug "${FUNCNAME[0]}: src: $src, dest: $dest"
    # if $dest_snap's received_uuid is the same as $src_snap's uuid, then
    # it means that these snapshots are identical.
    local dest_mount_point=$(mount_point_of $dest)
    local uuid_of_src="$(get_btrfs_uuid $src)"
    local snap_already_sent=""

    echo_debug "uuid_of_src: $uuid_of_src"
    echo_debug "dest_mount_point: $dest_mount_point"

    if [[ ! -z $uuid_of_src ]]; then
        snap_already_sent=$(btrfs sub list -R $dest_mount_point | grep $uuid_of_src )
        echo_debug "snap already sent (raw): $snap_already_sent"

        if [[ "$snap_already_sent" != "" ]]; then
            snap_found="$dest_mount_point/$(echo $snap_already_sent | get_line_field 'path')"
            echo "$(readlink -m $snap_found)"
            return 0
        fi
    fi

    # try the reverse
    local received_uuid_of_local="$(get_btrfs_received_uuid $src)"
    if [[ ! -z $received_uuid_of_local ]]; then
        dest_mount_point=$(mount_point_of $dest)
        snap_already_sent=$(btrfs sub list -u $dest_mount_point | grep "$received_uuid_of_local" )

        echo_debug "received_uuid_of_local: $received_uuid_of_local"
        echo_debug "dest_mount_point: $dest_mount_point"
        echo_debug "snap already sent (raw): $snap_already_sent"

        if [[ "$snap_already_sent" != "" ]]; then
            snap_found="$dest_mount_point/$(echo $snap_already_sent | get_line_field 'path')"
            echo "$(readlink -m  $snap_found)"
            return 0
        fi
    fi
}



get_line_field () {
    # returns the word after a specific $field in a line
    local field=$1
    grep -oP "(?<=$field )[^ ]+"
}

get_btrfs_received_uuid () {
    local subvol=$1
    local uuid=$(btrfs sub show $subvol | grep "Received UUID:" | awk -F: '{print $2}' | sed -e "s/\s//g")
    [ $? -ne 0 ] && echo_err "in ${FUNCNAME[0]}"
    [ ${#uuid} -eq 36 ] && echo $uuid
}

get_btrfs_uuid () {
    local subvol=$1
    local uuid=$(btrfs sub show $subvol | grep "^\s*UUID:" | awk -F: '{print $2}' | sed -e "s/\s//g")
    [ $? -ne 0 ] && echo_err "in ${FUNCNAME[0]}"
    [ ${#uuid} -eq 36 ] && echo $uuid
}

get_btrfs_parent_uuid () {
    local subvol=$1
    local uuid=$(btrfs sub show $subvol | grep "Parent UUID:" | awk -F: '{print $2}' | sed -e "s/\s//g")
    [ $? -ne 0 ] && echo_err "in ${FUNCNAME[0]}"
    [ ${#uuid} -eq 36 ] && echo $uuid
}

mount_point_of () {
    local file=$1
    findmnt -n -o TARGET --target $file
}

is_snap_safe_to_del () {
    # a snapshot can be deleted as long as there is at least one common
    # reference snapshot left in both snapshot folders.
    local snap_to_del=$1
    local source_snaps=$2
    if [[ "$2" == "" ]]; then
        echo_err "Usage: ${FUNCNAME[0]} snap_to_del source_snaps_to_check"
    fi

    #DEBUG=true
    echo_debug "snap to del: $snap_to_del"
    echo_debug "==========================================="
    local the_last_snap_in_dest=""
    local snap_in_dest=""
    while read -a src; do
        echo_debug "scr is: $src"
        snap_in_dest=$(get_snapshot_in_dest $src $(dirname $snap_to_del))
        echo_debug "snap_in_dest is: $snap_in_dest (src: $src, dest: $(dirname $snap_to_del))"
        if [[ ! -z "$snap_in_dest" ]] && [[ "$snap_in_dest" != "$snap_to_del" ]]; then
            echo_debug "already sent snap found: $snap_in_dest"
            the_last_snap_in_dest="$snap_in_dest"
        else
            if [[ -z "$snap_in_dest" ]]; then
                echo_debug "this snapshot ($src) is not in the destination"
            else
                echo_debug "This is the source snap already!!!"
            fi
        fi
    done < <(snapshots_in $source_snaps)

    if [[ ! -z "$the_last_snap_in_dest" ]]; then
        echo_debug "the last snap in dest: $the_last_snap_in_dest"
        echo_debug "$(echo btrfs sub show $the_last_snap_in_dest)"
        return 0
    else
        echo_debug "this snapshot is UNSAFE TO DELETE"
        return 1
    fi
}

take_snapshot () {
    local src=$1
    local dest=$2
    btrfs sub snap -r "$src" "$dest"
}

dirname_two () {
    # return the last 2 portions of dirname:
    local param=$1
    echo "$(basename $(dirname $param))/$(basename $param)"
}

assert_test () {
    local expected=$1
    local result=$2
    if [[ "$expected" != "$result" ]]; then
        echo_err "Test failed! (expected: $expected, result: $result)"
    else
        echo_green "Test passed..."
    fi
}

get_free_space_of_snap () {
    # returns in KBytes
    local snap=$1
    df -k --sync --output=avail $snap | sed '2q;d'
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
