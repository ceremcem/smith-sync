#!/bin/bash
_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
set -eu

config=${1:-}

[[ -f $config ]] || { \
    cat << EOL

Description:

Generates BTRBK config file by adding subvolumes into the 
configuration under \$subvolume.

Required \$snapshot_dir's are created automatically.

Usage:

    $(basename $0) path/to/orig.config > generated.config

Then use the generated.config as usual.

EOL
    exit 1;
}

errcho(){ >&2 echo -e "$@"; }

# Print the original config
cat $config
echo

# Print generated config
while read key value; do
    case $key in
        snapshot_dir|volume|subvolume|target)
            declare $key=$value
            ;;
    esac
done < $config

# TODO: assign them to an array
src="$volume/$subvolume"
dest="$volume/$snapshot_dir"
target=${target:-}

exclude_list=("tmp")

$_sdir/btrfs-ls --only-rw "$src" | while read sub; do
    [[ "$(basename $sub)" == "tmp" ]] && {  errcho "Skipping $sub..."; continue; }
    rel=$(readlink -m "${sub#${src%/}}")
    new_snapshot_dir=$(readlink -m $dest/$(dirname $rel))
    #echo will backup $sub like $new_snapshot_dir/$(basename $sub).1234567890;
    _subvolume="${sub#$volume/}"
    _snapshot_dir="${new_snapshot_dir#$volume/}"
    [[ -n $target ]] && _target="$target/$(dirname $rel)"
    if [[ ! -d "$new_snapshot_dir" ]]; then
        errcho "Creating $new_snapshot_dir"
        sudo mkdir -p "$new_snapshot_dir"
    fi
    if [[ -n "$target" && -d "$target" && ! -d "$_target" ]]; then
        errcho "Creating $_target"
        sudo mkdir -p "$_target"
    fi
    # Generate actual BTRBK configuration
    echo "volume    $volume"
    echo "  subvolume       $_subvolume"
    echo "  snapshot_dir    $_snapshot_dir"
    [[ -n $target ]] && \
        echo "  target          $_target"
    echo
done


