#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

suffix=".DO_NOT_DELETE"

show_help(){
    cat <<HELP
    $(basename $0) [options] /path/to/snapshots/dir

    Options:

        (Actions)
        --freeze         : Freeze latest snapshots by creating new snapshots with the suffix.
        --unfreeze       : Unfreeze the copy of frozen snapshots.
        --clean          : Clean (delete) the frozen snapshots.
        --show           : Show frozen subvolumes if exist.
        --get-latest-ts  : Get timestamp of latest snapshots.
        --rename-to .NEW : Rename the current suffixes to the ".NEW" string

        --timestamp TS   : Use TS as the timestamp, instead of latest
        --suffix STR     : Use STR as the suffix. Default: "$suffix"

        --fix-received TARGET_PATH : Fix the "Received UUID" attribute of the snapshots in 
                                     TARGET_PATH by replacing them with the UUID of the snapshots
                                     that have the same filename in source directory.

HELP
}

die(){
    >&2 echo
    >&2 echo "$@"
    >&2 echo
    exit 1
}

help_die(){
    >&2 echo
    >&2 echo "$@"
    >&2 echo
    show_help
    exit 1
}

# Parse command line arguments
# ---------------------------
# Initialize parameters
action=
snapshots_dir=
timestamp=
new_suffix=
target_dir=
# ---------------------------
args_backup=("$@")
args=()
_count=1
while [ $# -gt 0 ]; do
    key="${1:-}"
    case $key in
        -h|-\?|--help|'')
            show_help    # Display a usage synopsis.
            exit
            ;;
        # --------------------------------------------------------
        --freeze)
            action="freeze"
            ;;
        --unfreeze)
            action="unfreeze"
            ;;
        --show)
            action="show"
            ;;
        --clean)
            action="clean"
            ;;
        --rename-to) shift
            action="rename"
            new_suffix="${1:-}"
            [[ -z "${new_suffix:-}" ]] && die "New suffix is required"
            ;;
        --get-latest-ts)
            action="get-ts"
            ;;
        --timestamp) shift
            timestamp=$1
            ;;
        --suffix) shift
            suffix=$1
            ;;
        --fix-received) shift
            target_dir=$1
            ;;
        # --------------------------------------------------------
        -*) # Handle unrecognized options
            help_die "Unknown option: $1"
            ;;
        *)  # Generate the new positional arguments: $arg1, $arg2, ... and ${args[@]}
            if [[ ! -z ${1:-} ]]; then
                declare arg$((_count++))="$1"
                args+=("$1")
            fi
            ;;
    esac
    [[ -z ${1:-} ]] && break || shift
done; set -- "${args_backup[@]-}"
# Use $arg1 in place of $1, $arg2 in place of $2 and so on, 
# "$@" is in the original state,
# use ${args[@]} for new positional arguments  

snapshots_dir="${arg1:-}"

# Argument checking
# -----------------------------------------------
[[ -z ${snapshots_dir:-} ]] && help_die "Snapshots dir can not be empty"
[[ -z ${action:-} ]] && help_die "You must choose an action."

[[ $(whoami) = "root" ]] || { sudo $0 "$@"; exit 0; }

get_latest_ts(){
    btrfs-ls --ro "$snapshots_dir" \
        | grep -oE -- '[0-9]{8}T[0-9]{4}$' \
        | sort -n \
        | tail -n 1
}

do_freeze(){
    latest_timestamp=${timestamp:-$(get_latest_ts)}
    echo "Using timestamp: $latest_timestamp"

    while read -r sub; do
        if ! [[ -d "${sub}${suffix}" ]]; then
            echo "Freezing: $sub"
            btrfs sub snap -r "$sub" "${sub}${suffix}"
        else
            echo "Already frozen: $sub"
        fi
    done <<< $(btrfs-ls --ro "$snapshots_dir" | grep "${latest_timestamp}$")
}

do_show(){
    btrfs-ls --ro "$snapshots_dir" | grep "$(echo $suffix | sed 's/\./\\./g')$"
}

do_unfreeze(){
    export PYTHONPATH="${PYTHONPATH:-}:$_sdir/python-btrfs/"
    while read -r sub; do
        [[ -z "$sub" ]] && continue
        echo "Unfreezing: $sub"
        orig="${sub%$suffix}"
        if [[ -d "$orig" ]]; then
            echo "Already exists: $sub"
        else
            btrfs sub snap -r "$sub" "$orig"
        fi
        if [[ -n "$target_dir" ]]; then
            local target_snap="$target_dir/$(realpath --relative-to="$snapshots_dir" "$orig")"
            local t_recv_uuid=$(btrfs sub show $target_snap | egrep "^\s+Received UUID" | cut -d: -f2 | tr -d '[:space:]')
            local s_uuid=$(btrfs sub show $orig | egrep "^\s+UUID:" | cut -d: -f2 | tr -d '[:space:]')
            if [[ "$t_recv_uuid" != "$s_uuid" ]]; then
                echo "Will fix target Received UUID: $target_snap ($t_recv_uuid -> $s_uuid)"
                btrfs property set -ts $target_snap ro false
                $_sdir/set_received_uuid.py $s_uuid $target_snap
                btrfs property set -ts $target_snap ro true
            else
                echo "Received UUID is good: $target_snap" 
            fi
        fi
    done <<< $(do_show)
}

do_clean(){
    while read -r sub; do
        [[ -z "$sub" ]] && continue
        btrfs sub del "$sub"
    done <<< $(do_show)
}

do_rename(){
    while read -r sub; do
        [[ -z "$sub" ]] && continue
        orig="${sub%$suffix}"
        _new="${orig}${new_suffix}"
        echo "Renaming: $sub to $(basename $_new)"
        mv "$sub" "$_new"
    done <<< $(do_show)
}

# Execute the chosen action
case $action in
    show)       do_show;;
    freeze)     do_freeze;;
    unfreeze)   do_unfreeze;;
    clean)      do_clean;;
    get-ts)     get_latest_ts;;
    rename)     do_rename;;
esac
