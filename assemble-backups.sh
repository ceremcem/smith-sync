#!/bin/bash
set -eu

die(){
    echo 
    echo "ERROR: $@"
    echo
    exit 1
}

# show help
show_help(){
    cat <<HELP

    $(basename $0) path/to/snapshots-root [path/to/dest]

    If path/to/dest is omitted, only latest snapshots are listed. 

    Options:
        --dry-run           : Dry run, don't touch anything actually

HELP
    exit
}

# Parse command line arguments
# ---------------------------
# Initialize parameters
dryrun=false
# ---------------------------
args_backup=("$@")
args=()
_count=1
while :; do
    key="${1:-}"
    case $key in
        -h|-\?|--help|'')
            show_help    # Display a usage synopsis.
            exit
            ;;
        # --------------------------------------------------------
        --dry-run)
            dryrun=true
            ;;
        # --------------------------------------------------------
        -*) # Handle unrecognized options
            die "Unknown option: $1"
            ;;
        *)  # Generate the new positional arguments: $arg1, $arg2, ... and ${args[@]}
            if [[ ! -z ${1:-} ]]; then
                declare arg$((_count++))="$1"
                args+=("$1")
            fi
            ;;
    esac
    shift
    [[ -z ${1:-} ]] && break
done; set -- "${args_backup[@]}"
# Use $arg1 in place of $1, $arg2 in place of $2 and so on, 
# "$@" is in the original state,
# use ${args[@]} for new positional arguments  

checkrun(){
    if [[ $dryrun == true ]]; then
        echo "[DRY RUN] $@"
    else
        echo "+ $@"
        $@
    fi
}

src=$arg1
dest=${arg2:-}

ext_regex=".+(\.20[0-9]{6}T[0-9]{4}_?[0-9]?)"
get_latest(){
    local reinspect=()
    local latest=
    local path=$1
    local orig_path=${2:-$path}
    while read -r sub; do
        if ! [[ $sub =~ $ext_regex ]]; then
            [[ -n $sub ]] && reinspect+=("$sub")
            continue
        fi
        latest="$sub"
    done <<< $( ls -1 $path | sort )
    [[ -n "$latest" ]] && echo "${path##$orig_path}/$latest"
    for s in "${reinspect[@]}"; do
        get_latest "$path/$s" "$orig_path"
    done
}

[[ -n $dest ]] && [[ -e $dest ]] && die "Destination ($dest) exists."

[[ $dryrun = true || $(whoami) = "root" ]] || die "This script must be run as root."

backups=($(get_latest $src))

if [[ -z $dest ]]; then
    for backup in ${backups[@]}; do
        echo "$backup"
    done
    exit 0
fi

rootfs=
for backup in ${backups[@]}; do
    target=$(echo ${backup%.*})
    _dest=$dest/$target
    _src=$src$backup

    if [[ $(dirname $target) == "/" ]]; then
        _dest="$dest"
        rootfs=$_src
    else
        if [[ $dryrun = false && -d $_dest ]] || [[ $dryrun = true && -d $rootfs/$target ]]; then
            checkrun rmdir "$_dest"
        else
            [[ $dryrun = true ]] && _x=$rootfs/$target || _x=$_dest
            if ! [[ -d $(dirname $_x) ]]; then
                echo "Skipping $_x (not existed in source)"
                continue
            fi
        fi
    fi
    checkrun btrfs sub snap $_src $_dest
done
