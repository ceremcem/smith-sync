#!/bin/bash

# run as root
[[ $(id -u) > 0 ]] && { sudo $0 "$@"; exit 0; }

set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

safe_source $DIR/../common.sh
safe_source $DIR/tests-config.sh

TEST_SUBS="$DIR/test-subvolumes"

echo_green "* Configuring test..."
echo "* Validating TEST_FOLDER"
if ! is_btrfs_subvolume $TEST_FOLDER; then
    echo_err "TEST_FOLDER ($TEST_FOLDER) should be a valid btrfs subvolume!"
fi

name="testing_tmp"
if [[ "$(basename $TEST_FOLDER)" != "$name" ]]; then
    echo_err "TEST_FOLDER name should be '$name'"
fi

if [[ "$(mount_point_of $TEST_FOLDER)" == "$(mount_point_of $TEST_SUBS)" ]]; then
    echo_err "TEST_FOLDER should be on another BTRFS partition!"
fi

if ! prompt_yes_no "TEST_FOLDER = $TEST_FOLDER. OK?"; then
    echo_err "Please set test folder in test-config.sh"
fi
