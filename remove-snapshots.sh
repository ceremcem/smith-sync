#!/bin/bash
set -u
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

show_help(){
    cat <<HELP
    $(basename $0) /path/to/snapshots options

    Options:
        --before [TIMESTAMP]    : Remove all snapshots before that timestamp 
                                  (leave empty for the list of available timestamps)
        --preserve-last N       : Remove all snapshots except for this amount 
                          of latest snapshots
        --apply                 : No dry-run, actually apply.

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
limit_string=
dry_run=true
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
            [[ -n ${1:-} ]] && limit_string="--after $1" || help_needed=true
            ;;
        --preserve-last) shift
            limit_string="--last $1"
            ;;
        --apply)
            dry_run=false
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

if $help_needed; then 
    echo "Please provide a timestamp:"
    echo "---------------------------"
    $_sdir/list-backup-dates.sh $snapshots
    exit 1
fi

[[ -n ${limit_string:-} ]] || die "--before or --preserve-last is required."

readarray -t to_be_saved < <($_sdir/list-backup-dates.sh $snapshots $limit_string)
for s in ${to_be_saved[@]}; do
    echo "Will be saved: $s"
done
 
for snap in `$_sdir/btrfs-ls $snapshots`; do
    save=false
    for del in "${to_be_saved[@]}"; do
        if echo "$snap" | grep -q "\.$del"; then
            save=true
            break
        fi
    done
    if $save; then 
        echo "to be saved: $snap"
    else
        echo "REMOVE: $snap"
        [[ $dry_run == false ]] && sudo btrfs sub del "$snap"
    fi
done

if $dry_run; then
    echo "This was a dry run. Provide --apply switch if you want to apply."
fi
