#!/bin/bash

TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $TEST_DIR/../common.sh
. $TEST_DIR/tests-config.sh


echo_green "* Configuring test..."

if ! is_btrfs_subvolume $TEST_FOLDER; then
    echo_err "TEST_FOLDER should be a valid btrfs subvolume!"
fi

name="testing_tmp"
if [[ "$(basename $TEST_FOLDER)" != "$name" ]]; then
    echo_err "TEST_FOLDER name should be '$name'"
fi

prompt_yes_no "Using $TEST_FOLDER as \$TEST_FOLDER. Is that OK?"

TEST_SUBS="$TEST_DIR/test-subvolumes"
echo "removing $TEST_SUBS if possible"
rm -rf $TEST_SUBS 2> /dev/null
echo "re-creating $TEST_SUBS"
mkdir $TEST_SUBS || echo_err "Creating $TEST_SUBS is not possible!"

echo "clearing $TEST_FOLDER if possible"
rm -rf $TEST_FOLDER/* 2> /dev/null

echo_green "* Starting test..."
