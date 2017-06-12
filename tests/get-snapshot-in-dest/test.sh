# First test:
result=$(get_snapshot_in_dest $TEST_SUBS/a-1 $TEST_FOLDER)
expected="$TEST_FOLDER/a-1"
assert_test $expected $result

# Second test: rename file, expect function to find the new name
mv $TEST_FOLDER/a-1 $TEST_FOLDER/foo
result=$(get_snapshot_in_dest $TEST_SUBS/a-1 $TEST_FOLDER)
expected="$TEST_FOLDER/foo"
assert_test $expected $result

# Third test: try to find remote snapshot in local folder
result=$(get_snapshot_in_dest $TEST_FOLDER/foo $TEST_SUBS)
expected="$TEST_SUBS/a-1"
assert_test $expected $result
