#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

suffix=".DO_NOT_DELETE"

show_help(){
    cat <<HELP
    $(basename $0) [options] /path/to/snapshots/dir
    Options:
        --freeze        : Freeze latest snapshots (by adding "$suffix" suffix).
        --unfreeze      : Unfreeze the copy of frozen snapshots.
        --clean         : Clean (delete) the frozen snapshots.
        --show          : Show frozen subvolumes if exist.
        --get-latest-ts : Get timestamp of latest snapshots.
        --timestamp TS  : Use TS as the timestamp, instead of latest
        --suffix STR    : Use STR as the suffix, instead of "$suffix".

HELP
}

die(){
    >&2 echo
    >&2 echo "$@"
    exit 1
}

help_die(){
    >&2 echo
    >&2 echo "$@"
    show_help
    exit 1
}

# Parse command line arguments
# ---------------------------
# Initialize parameters
freeze=false
unfreeze=false
show=false
clean=false
get_ts=false
snapshots_dir=
timestamp=
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
            freeze=true
            ;;
        --unfreeze)
            unfreeze=true
            ;;
        --show)
            show=true
            ;;
        --clean)
            clean=true
            ;;
        --get-latest-ts)
            get_ts=true
            ;;
        --timestamp) shift
            timestamp=$1
            ;;
        --suffix) shift
            suffix=$1
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

# Empty argument checking
# -----------------------------------------------
[[ -z ${snapshots_dir:-} ]] && die "Snapshots dir can not be empty"
$freeze || $unfreeze || $clean || $show || $get_ts || die "You must choose an action."

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
    btrfs-ls --ro "$snapshots_dir" | grep "$suffix"
}

do_unfreeze(){
    while read -r sub; do
        [[ -z "$sub" ]] && continue
        echo "Unfreezing: $sub"
        orig="${sub%$suffix}"
        if [[ -d "$orig" ]]; then
            echo "Already exists: $sub"
        else
            btrfs sub snap -r "$sub" "$orig"
        fi
    done <<< $(do_show)
}

do_clean(){
    while read -r sub; do
        [[ -z "$sub" ]] && continue
        btrfs sub del "$sub"
    done <<< $(do_show)
}

# Execute chosen action
$show && do_show
$freeze && do_freeze
$unfreeze && do_unfreeze
$get_ts && get_latest_ts
$clean && do_clean
