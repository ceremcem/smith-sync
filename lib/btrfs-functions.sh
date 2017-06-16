btrfs_send_diff () {
    local parent=$1
    local current=$2
    if [[ -z $current ]]; then
        current=$1
        echo_yellow "No parent specified, sending whole snapshot ($current)"
        if prompt_yes_no "Normally this might happen only in new disks. Should we really send whole snapshot?"; then
            btrfs send $current
        else
            echo "Skipped sending $current"
            return
        fi
    else
        echo_green "Sending difference between $parent and $current"
        if [[ "$(mount_point_of $parent)" != "$(mount_point_of $current)" ]]; then
            echo_red "USAGE PROBLEM: parent and current snapshots should reside at the same disk!"
            return 255
        fi
        btrfs send -p $parent --no-data $current 2> /dev/null > /dev/null
        if [[ $? != 0 ]]; then
            echo_red "WE DETECT AN ERROR in ${FUNCNAME[0]}! parent: $parent, curr: $current"
            echo_red "Command was: btrfs send -p $parent --no-data $current"
            exit
        else
            btrfs send -p $parent $current
        fi
    fi
}

take_snapshot () {
    local src=$1
    local dest=$2
    btrfs sub snap -r "$src" "$dest"
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

last_snapshot_in () {
    local TARGET=$1
    snapshots_in $TARGET | tail -n 1
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

is_btrfs_subvolume() {
    local subvol=$1
    btrfs subvolume show "$subvol" >/dev/null 2>&1
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

require_being_btrfs_subvolume () {
    local subvol=$1
    if ! is_btrfs_subvolume $subvol; then
    	echo_err "$subvol not found, create it first."
    fi
}
