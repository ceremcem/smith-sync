#!/bin/bash

if [[ $(id -u) > 0 ]]; then
    #echo "This script needs root privileges..."
    sudo $0 "$@"
    exit
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DEBUG=false

source $DIR/lib/basic-functions.sh
source $DIR/lib/fs-functions.sh
source $DIR/lib/btrfs-functions.sh
source $DIR/lib/sync-functions.sh
