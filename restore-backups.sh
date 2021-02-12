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

    If path/to/dest is omitted, matching snapshots are only printed.

    Options:
        --dry-run           : Dry run, don't touch anything actually
        --date TIMESTAMP    : Return only the snapshots matching with the TIMESTAMP.
                              Default: "latest"

        --every-latest      : Return every latest snapshot of available snapshots

HELP
    exit
}

# Parse command line arguments
# ---------------------------
# Initialize parameters
dryrun=false
snapshot_date="latest"
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
        --date) shift
            snapshot_date=$1
            ;;
        --every-latest)
            snapshot_date=""
            ;;
        # --------------------------------------------------------
        -*) # Handle unrecognized options
            echo "Unknown option: $1"
            show_help
            die
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

ext_regex="(\.20[0-9]{6}T[0-9]{4}_?[0-9]?)"
get_latest(){
    local reinspect=()
    local snaps=()
    local names=()
    local path=$1
    local orig_path=${2:-$path}
    while read -r sub; do
        if ! [[ $sub =~ .+$ext_regex ]]; then
            [[ -n $sub ]] && reinspect+=("$sub")
            continue
        fi
        # this is a snapshot
        snaps+=("$sub")

        name=$(echo $sub | sed -r "s/$ext_regex$//")
        for n in ${names[@]}; do
            [[ "$n" == "$name" ]] && continue 2
        done
        names+=("$name")
    done <<< $( ls -1 $path | sort )
    local get_latest=false
    [[ "$snapshot_date" == "latest" ]] && get_latest=true
    if [ ${#snaps[@]} -gt 0 ]; then 
        for name in "${names[@]}"; do
            local latest=
            for snap in ${snaps[@]}; do
                [[ "$snap" =~ ${name}${ext_regex}$ ]] || continue # filter snapshots prefixed with $name
                if [[ "$snap" > "$latest" ]]; then 
                    if $get_latest; then 
                        # set the latest snapshot date
                        snapshot_date=${snap##$name.}
                    fi
                    if [[ -z $snapshot_date ]]; then 
                        latest=$snap
                    else 
                        if [[ "${snap##$name.}" == "$snapshot_date" ]]; then
                            latest=$snap
                        fi
                    fi
                fi
            done
            [[ -n $latest ]] && echo "${path##$orig_path}/$latest"
        done
    fi
    for s in "${reinspect[@]}"; do
        get_latest "$path/$s" "$orig_path"
    done
}

[[ $dryrun = true || $(whoami) = "root" ]] || die "This script must be run as root."

backups=($(get_latest $src))

# only print and exit
if [[ -z $dest ]]; then
    for backup in ${backups[@]}; do
        echo "$backup"
    done
    exit 0
fi

[[ ${#backups[@]} -eq 0 ]] && die "No backups found in $src"

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
        fi
    fi
    checkrun btrfs -q sub snap $_src $_dest
done
