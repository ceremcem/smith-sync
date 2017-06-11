#!/bin/bash
[[ $(id -u) > 0 ]] && { sudo $0 "$@"; exit 0; }

TEST_NAME=$1

set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

safe_source $DIR/tests-common.sh
safe_source $DIR/$TEST_SCRIPT_DIR/test${TEST_SCRIPT_NUM}.sh
