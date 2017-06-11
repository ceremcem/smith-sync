#!/bin/bash

TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $TEST_DIR/../common.sh
. $TEST_DIR/tests-config.sh


if ! is_btrfs_subvolume $TEST_FOLDER; then
    echo_err "TEST_FOLDER should be a valid btrfs subvolume!"
fi

name="testing_tmp"
if [[ "$(basename $TEST_FOLDER)" != "$name" ]]; then
    echo_err "TEST_FOLDER name should be '$name'"
fi

prompt_yes_no "Using $TEST_FOLDER as \$TEST_FOLDER. Is that OK?"

SRC_TEST_SUBVOLUMES="$TEST_DIR/test-subvolumes"
echo "removing $SRC_TEST_SUBVOLUMES if possible"
rm -rf $SRC_TEST_SUBVOLUMES 2> /dev/null
echo "re-creating $SRC_TEST_SUBVOLUMES"
mkdir $SRC_TEST_SUBVOLUMES || echo_err "Creating $SRC_TEST_SUBVOLUMES is not possible!"

echo "clearing $TEST_FOLDER if possible"
rm -rf $TEST_FOLDER/* 2> /dev/null
