#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
# end of bash boilerplate

safe_source $_sdir/lib/all.sh

# do not exit on errors
set +e

# show help
show_help(){
    cat <<HELP

    $(basename $0) [options] /path/to/source /path/to/destination
    Options:
        --dry-run       : Dry run, don't touch anything actually
        -u              : Unattended run, don't show yes/no prompt
        --ssh           : Switch to SSH mode (TODO)

HELP
    exit
}

die () {
    echo
    echo_red "$1"
    show_help
    exit 255
}


# Parse command line arguments
# ---------------------------
# Initialize parameters
dry_run=false
unattended=false
iredir=false # internal redirect
# ---------------------------
args=("$@")
_count=1
while :; do
    key="${1:-}"
    case $key in
        -h|-\?|--help|'')
            show_help    # Display a usage synopsis.
            exit
            ;;
        # --------------------------------------------------------
        --dry-run) shift
            dry_run=true
            ;;
        -u) shift
            unattended=true
            ;;
        --internal-redirect) shift
            iredir=true
            ;;

        # --------------------------------------------------------
        -*) # Handle unrecognized options
            echo
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)  # Generate the positional arguments: $_arg1, $_arg2, ...
            [[ ! -z ${1:-} ]] && declare _arg$((_count++))="$1" && shift
    esac
    [[ -z ${1:-} ]] && break
done; set -- "${args[@]}"
# use $_arg1 in place of $1, $_arg2 in place of $2 and so on, "$@" is intact

src=${_arg1:-}
dest=${_arg2:-}

[[ -z $src ]] && die "Source can not be empty"
[[ -z $dest ]] && die "Destination can not be empty"

if [[ ! -d $dest ]]; then
    die "sync directory must exist: $dest"
fi

[[ $iredir = false ]] && echo_green "Using destination directory: $dest"

if [[ $unattended = false ]]; then
    if ! prompt_yes_no "Should we really continue?"; then
        echo_info "Interrupted by user."
        exit 0
    fi
fi

# All checks are done, run as root
[[ $(whoami) = "root" ]] || { sudo $0 "$@" -u --internal-redirect; exit 0; }

# Cleanup code (should be after "run as root")
sure_exit(){
    echo
    echo_yellow "Interrupted by user."
    exit 5
}
cleanup(){
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo_green "Have a nice day."
    else
        echo_red "Something went wrong: Code: $exit_code"
    fi
    exit $exit_code
}
trap sure_exit SIGINT # Runs on Ctrl+C, before EXIT
trap cleanup EXIT



RSYNC="nice -n19 ionice -c3 rsync"
SSH="ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o AddressFamily=inet"
# SSH options:    --rsh="$SSH" --rsync-path="sudo rsync" target_$conn_method:$source $sync_dir

start_timer

# build rsync params
_param=
[[ $dry_run = true ]] && _param="$_param --dry-run"

for i in `seq 1 3`; do
    $RSYNC -aHAXvPh ${_param} --delete --delete-excluded --exclude-from "$_sdir/exclude-list.txt" "$src" "$dest"
    exit_code=$?
    if [ $exit_code -eq 11 ]; then
        echo_red "NO Space Left on the device (code $exit_code)"
        # It's useful to retry on "No Space Left on the device" error on BTRFS because 
        # user might have deleted some big snapshots recently and btrfs-cleanup might be still 
        # working on freeing the available space. 
        # TODO: Retry only if it's BTRFS filesystem.
        retry="10m"
        echo_yellow "...will retry in $retry"
        sleep ${retry}
        echo_green "...Retrying..."
        continue
    fi
    break
done

show_timer "sync completed in:"

exit $exit_code
