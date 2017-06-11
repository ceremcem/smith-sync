#!/bin/bash 
[[ $(id -u) > 0 ]] && { sudo $0 "$@"; exit 0; }

TEST_NAME=$1

set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

safe_source $DIR/tests-common.sh

if [[ -z $TEST_NAME ]] || [[ ! -d "$DIR/$TEST_NAME" ]]; then
    echo "TEST_NAME: $TEST_NAME"
    echo_err "Usage: $0 my-test/ "
fi
if [[ ! -f "$DIR/$TEST_NAME/test.sh" ]]; then
    echo_err "Your test should include a 'test.sh'"
fi

safe_source $DIR/$TEST_NAME/test.sh
