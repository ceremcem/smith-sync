btrfs sub delete $TEST_FOLDER/a-1
result=$(get_snapshot_in_dest $TEST_SUBS/a-2 $TEST_FOLDER)
expected="$TEST_FOLDER/a-2"
assert_test $expected $result

if ! is_snap_safe_to_del $TEST_FOLDER/a-2 $TEST_SUBS; then
    echo_err "$TEST_FOLDER/a-2 should be safe to del"
fi

btrfs sub delete $TEST_FOLDER/a-2
result=$(get_snapshot_in_dest $TEST_SUBS/a-3 $TEST_FOLDER)
expected="$TEST_FOLDER/a-3"
assert_test $expected $result
