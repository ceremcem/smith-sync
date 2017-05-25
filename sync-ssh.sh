#!/bin/bash 

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/backup-common.sh

if [[ $(id -u) > 0 ]]; then 
    echo "This script needs root privileges..."
    sudo $0
    exit
fi 

# ----------------------------------
# Do not use "-d" switch to delete snapshots 
# ----------------------------------

SSH="ssh://aea3"

echo "Syncing $SRC1_SNAP"
buttersink $SRC1_SNAP/ $SSH/$DEST_SSH_SNAP 

echo "Syncing $SRC2_SNAP"
buttersink $SRC2_SNAP/ $SSH/$DEST_SSH_SNAP 
#exec_limited rsync -avP /boot 
