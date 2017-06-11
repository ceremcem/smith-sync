#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/tests-common.sh

btrfs sub create $TEST_SUBS/a


prompt_yes_no "Test ended. Should we cleanup test files?"
btrfs sub delete $TEST_SUBS/a
