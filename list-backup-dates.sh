#!/bin/bash
set -eu 
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
# end of bash boilerplate

# magic variables
# $_dir  : this script's (or softlink's) directory
# $_sdir : this script's real file's directory

show_help(){
    cat <<HELP
    $(basename $0) [options] /path/to/snapshots

    Options:
        --before TIMESTAMP     : List before that timestamp (YYYYmmddTHHMM) 
                                 (exclusive)
        --after TIMESTAMP      : List after that timestamp 
                                 (inclusive)
        --last N               : Number of latest snapshots 

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
before_ts=
after_ts=
last=
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
        --before) shift
            before_ts=$1
            ;;
        --after) shift
            after_ts=$1
            ;;
        --last) shift
            last=$1
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
done; set -- "${args_backup[@]}"
# Use $arg1 in place of $1, $arg2 in place of $2 and so on, 
# "$@" is in the original state,
# use ${args[@]} for new positional arguments  

[[ -n ${arg1:-} ]] && snapshots=$arg1 || die "Snapshot path is required."

counter=0
for i in `ls $snapshots | sort -n -r`; do
    [[ $i =~ \.[0-9]{8}T[0-9]{4}.* ]] || continue
    base=$(basename $i)
    timestamp=${base##*.}
    [[ -n ${before_ts:-} ]] && { [[ $timestamp < $before_ts ]] || continue; }
    [[ -n ${after_ts:-} ]] && { [[ $timestamp == $after_ts || $timestamp > $after_ts ]] || continue; }
    [[ -n ${last:-} ]] && { [[ $((counter++)) -lt $last ]] || break; }
    echo $timestamp
done
