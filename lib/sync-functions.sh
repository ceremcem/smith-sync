send_all_snapshots () {
    local SOURCE_SNAPS=$1
    local DESTINATION_SNAPS=$2

    echo_blue "Sendings snapshots from $SOURCE_SNAPS to $DESTINATION_SNAPS"
    echo_blue "===================================================================="

    local ref_snapshot=""
    set_reference () {
        local ref=$1
        if [[ -z $ref ]]; then
            echo_red "not setting ref as empty string, skipping!"
        else
            #echo_yellow "ref_snapshot = $ref"
            ref_snapshot=$ref
        fi
    }

    while read -a src; do
        #echo_info "------------------->>> $src -----------------------------"
        if [[ "$(get_snapshot_in_dest $src $DESTINATION_SNAPS)" != "" ]]; then
            echo_green "[\u2713] $src exists in destination, no need to send again."
            set_reference $src
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
                echo_red "DO NOT FORGET TO REMOVE $tmp_file"
            else
                # directly transfer
                # ------------------

                # estimate the size
                #estimate_btrfs_send_size $ref_snapshot $src

                # transfer
                btrfs_send_diff $ref_snapshot $src | pv | btrfs receive $DESTINATION_SNAPS
                set_reference $src
            fi
        fi
    done < <(snapshots_in $SOURCE_SNAPS)
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
