#!/bin/bash
set -eu
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source

die(){
    echo "$@"
    exit 1
}

# show help
show_help(){
    cat <<HELP

    $(basename $0) [options] -c path/to/config-file --from path/to/snapshots-root [--to path/to/dest]

    Options:
        --full           : Make a full installation (including Grub install)
        --refresh        : Delete old rootfs recursively, create it from the latest backups
        -c, --config     : Config file 
        --from           : Path to snapshots root. Relative to \$root_mnt or full path.
        --to             : Destination folder. \$root_mnt/\$subvol is used if omitted. 
        --boot-backup    : Path to /boot dir backups, relative to destination folder. Optional.
        --force-grub-install : Do not skip GRUB install phase even if dest/boot contents 
                                are not changed
        --debug-chroot   : Wait before exiting chroot environment

        And arguments where "./restore-backups.sh" accepts: 

        --date [YYYYmmddTHHMM] : Date to restore. Omit the date to get a list of
                                 available timestamps.

HELP
    exit
}

# Parse command line arguments
# ---------------------------
# Initialize parameters
full=false
refresh=false
config=
src=
dest=
boot_backup=
from_date=   # empty means "latest"
date=
force_grub_install=false
end_of_chroot="exit;" 
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
        --full)
            # install Grub, etc.
            full=true
            ;;
        --refresh)
            refresh=true
            ;;
        -c|--config) shift
            config=${1:-}
            ;;
        --from) shift
            src=${1:-}
            ;;
        --to) shift 
            dest=${1:-}
            ;;
        --boot-backup) shift
            boot_backup=$1
            ;;
        --date) shift 
            from_date="--date ${1:-}"
            date="${1:-}"
            ;;
        --force-grub-install)
            force_grub_install=true
            ;;
        --debug-chroot)
            end_of_chroot='echo "-----------------------------"; echo "Debug mode, type \"exit\" when you are done.";'
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
    [[ -z ${1:-} ]] && break || shift
done; set -- "${args_backup[@]}"
# Use $arg1 in place of $1, $arg2 in place of $2 and so on, 
# "$@" is in the original state,
# use ${args[@]} for new positional arguments

[[ -z $config ]] && die "Config file is required."
config=$(realpath $config)
cd "$(dirname "$config")"
source $config

[[ -z $src ]] && die "Source of snapshots is required."
[[ -d $root_mnt/$src ]] && src=$root_mnt/$src # relative path is used. 

[[ -z $dest ]] && dest="$root_mnt/$subvol"
echo "Using $dest as destination."

[[ $(whoami) = "root" ]] || die "This script must be run as root."
mountpoint $root_mnt > /dev/null || die "$root_mnt is not a mountpoint"

if [[ -n ${from_date:-} && -z ${date:-} ]]; then
    echo "Date should be one of the followings:" 
    ls -1 $src | egrep ".+\..+" | sed -r 's/.+\.//'    
    exit 1
fi

cd $_sdir

# recursively delete all snapshots in destination
if [[ $refresh == true && -d "$dest" ]]; then 
    echo "Recursively deleting $dest"
    $_sdir/btrfs-ls $dest | xargs btrfs sub del 
fi

if [[ -d $dest ]]; then
    echo "Using existing $dest snapshot."
else
    echo "Restoring $dest from backups ($src)"
    set -x
    ./restore-backups.sh $src $dest ${from_date:-}
    set +x
    # Workaround for ignored /var/tmp and /var/cache
    [[ -d $dest/var/tmp ]] || { btrfs sub create $dest/var/tmp; chmod 1777 $dest/var/tmp; } 
    [[ -d $dest/var/cache ]] || btrfs sub create $dest/var/cache
fi
./multistrap-helpers/install-to-disk/generate-scripts.sh $config -o $dest --update

if $full; then
    mount $boot_part $dest/boot
    grub_needs_to_be_installed=true
    if [[ -z $boot_backup ]]; then
        echo "No boot_backup folder is declared. Skipping restoring from boot backup"
    else
        if [[ -d $dest/$boot_backup ]]; then
            if ! $force_grub_install \
                && /usr/bin/diff -q $dest/$boot_backup/ $dest/boot/
            then 
                echo "Contents of $dest/boot has not been changed. "
                echo "WARNING: We should have compared the etc/default/grub** contents!"
                grub_needs_to_be_installed=false
            fi

            if $grub_needs_to_be_installed; then
                echo "Copying contents of \$dest/$boot_backup/ to \$dest/boot/"
                rsync -a --info=progress2 --delete $dest/$boot_backup/ $dest/boot/
            fi
        fi
    fi
    if $grub_needs_to_be_installed || $force_grub_install; then
        ./multistrap-helpers/install-to-disk/chroot-to-disk.sh $config "./2-install-grub.sh; $end_of_chroot"
    else
        echo "Skipping GRUB installation. (Use \"--force-grub-install\" if necessary.)"
    fi
    umount $boot_part
else 
    echo "INFO: Not required, skipping Grub re-installation."
fi
echo
echo "All done."
echo "Test with VirtualBox (Don't forget to unmount $root_mnt)"
