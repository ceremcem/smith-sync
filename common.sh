#!/bin/bash

if [[ $(id -u) > 0 ]]; then
    #echo "This script needs root privileges..."
    sudo $0 "$@"
    exit
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/config.sh

DEBUG=false

errcho () {
    >&2 echo -e "$*"
}

echo_err () {
	errcho "ERROR:"
	errcho "ERROR:"
	errcho "ERROR: $* "
	errcho "ERROR:"
	errcho "ERROR:"
	exit 1
}

echo_info () {
	errcho "INFO: $* "
}

echo_debug () {
    if $DEBUG; then
        errcho "DEBUG: $*"
    fi
}

echo_cont ()  {
    echo -ne "$*"
}

# http://webhome.csc.uvic.ca/~sae/seng265/fall04/tips/s265s047-tips/bash-using-colors.html

echo_green () {
    errcho "\e[1;32m$*\e[0m"
}

echo_blue () {
    errcho "\e[1;34m$*\e[0m"
}

echo_yellow () {
    errcho "\e[1;33m$*\e[0m"
}
echo_red () {
    errcho "\e[1;31m$*\e[0m"
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

start_timer () {
    echo_blue "(timer started)"
    start_date=$(date +%s)
}

show_timer () {
    local message="$*"
    if [[ -z $message ]]; then
        message="Duration: "
    fi
    end_date=$(date +%s)
    local time_diff=$(date -u -d "0 $end_date seconds - $start_date seconds" +"%H:%M:%S")
    echo_blue "$message $time_diff"
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

cleanup_dest_snapshots_by_disk_space () {
    local required_space=$1
    local SRC_SNAPSHOTS=$2
    local DEST_SNAPSHOTS=$3

    [ -z $DEST_SNAPSHOTS ] && echo_err "Usage: ${FUNCNAME[0]} size[M/G] src/ dest-to-delete/"

    echo_green "Getting incomplete snapshots in $DEST_SNAPSHOTS"
    while read -a snap; do
        if is_snap_safe_to_del $snap $SRC_SNAPSHOTS; then
            echo "it is safe to delete $snap"
        fi
    done < <(snapshots_in --incomplete $DEST_SNAPSHOTS)

    echo_yellow "Deleting incomplete snapshots in $DEST_SNAPSHOTS"
    while read -a snap; do
        if is_snap_safe_to_del $snap $SRC_SNAPSHOTS; then
            echo "it is safe to delete $snap"
            btrfs sub delete $snap
        fi
    done < <(snapshots_in --incomplete $DEST_SNAPSHOTS)

    echo_yellow "Checking if we can delete from $DEST_SNAPSHOTS"

    while read -a snap; do
        if is_snap_safe_to_del $snap $SRC_SNAPSHOTS; then
            echo "it is safe to delete $snap"
            if is_free_space_more_than $required_space $DEST_SNAPSHOTS; then
                echo "Free space is more than $required_space"
                break
            else
                echo "Free space is lower than $required_space, deleting $snap"
                breakpoint
                btrfs sub delete "$snap"
            fi
        else
            echo "IT IS NOT SAFE TO DELETE $snap"
        fi
    done < <(snapshots_in $DEST_SNAPSHOTS)
}

cleanup_src_snapshots_by_disk_space () {
    local required_space=$1
    local SRC_SNAPSHOTS=$2
    local DEST_SNAPSHOTS=$3

    [ -z $DEST_SNAPSHOTS ] && echo_err "Usage: ${FUNCNAME[0]} size[M/G] src-to-delete/ dest-to-check/"

    echo_yellow "Checking if we can delete from $SRC_SNAPSHOTS"

    while read -a snap; do
        if is_snap_safe_to_del $snap $DEST_SNAPSHOTS; then
            echo "it is safe to delete $snap"
            if is_free_space_more_than $required_space $SRC_SNAPSHOTS; then
                echo "Free space is more than $required_space"
                break
            else
                echo "Free space is lower than $required_space, deleting $snap"
                btrfs sub delete "$snap"
            fi
        else
            echo "IT IS NOT SAFE TO DELETE $snap"
        fi
    done < <(snapshots_in $SRC_SNAPSHOTS)
}

btrfs_send_diff () {
    local parent=$1
    local current=$2
    if [[ -z $current ]]; then
        echo_yellow "No parent specified, sending whole snapshot"
        current=$1
        btrfs send $current
    else
        echo_green "Sending difference between $parent and $current"
        btrfs send -p $parent $current
    fi
}

send_all_snapshots () {
    local SOURCE_SNAPS=$1
    local DESTINATION_SNAPS=$2

    echo_blue "Sendings snapshots from $SOURCE_SNAPS to $DESTINATION_SNAPS"
    echo_blue "===================================================================="

    local ref_snapshot=""
    while read -a src; do
        if [[ "$(get_snapshot_in_dest $src $DESTINATION_SNAPS)" != "" ]]; then
            echo "$src exists in destination, no need to send again."
            ref_snapshot=$src
            #breakpoint
        else
            echo "$src will be sent to destination."
            # Minimum difference algorithm:
            # --------------------------------
            # since this utility is designed to send incremental backups, most
            # probably the minimum amount of difference will be optained between the
            # previous snapshot which has been successfully sent to the destination
            # and this one.

            #breakpoint
            dest_snap_path="$DESTINATION_SNAPS/$(basename $src)"

            if is_btrfs_subvolume $dest_snap_path; then
                echo "trying to rename to backup the $dest_snap_path in destination."
                mv $dest_snap_path "$dest_snap_path.backup-$(get_timestamp)"
            fi

            if false; then
                # transfer over dump file
                # ------------------
                tmp_file="/home/ceremcem/tmp/$(basename $src)"
                btrfs send -v -p $ref_snapshot -f $tmp_file $src || echo_err "Problem in btrfs send"
                btrfs receive -f $tmp_file $DESTINATION_SNAPS
                echo "DO NOT FORGET TO REMOVE $tmp_file"
            else
                # directly transfer
                # ------------------

                # estimate the size
                #estimate_btrfs_send_size $ref_snapshot $src

                # transfer
                btrfs_send_diff $ref_snapshot $src | pv | btrfs receive $DESTINATION_SNAPS

                ref_snapshot="$(get_snapshot_in_dest $src $DESTINATION_SNAPS)"
                echo_info "Setting new reference snapshot as $ref_snapshot"
                #breakpoint
            fi
        fi

        echo_red "--------------------------------------------------------------------"
        continue
        if is_subvolume_successfully_sent $dest; then
            echo "subvol ok"
        else
            echo "subvol will be deleted"
            echo btrfs sub delete $snap
        fi

    done < <(snapshots_in $SOURCE_SNAPS)
}
