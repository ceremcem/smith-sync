
echo "Deleting all snapshots in $TEST_SUBS"
while read -a snap; do

    # TRICK IS THAT
    # We are intentionally using `is_snap_safe_to_del` function
    # since we should pass `snapshot_in_disk1` and `snapshot_folder_in_disk2`
    # but we are passing `snapshot_in_disk1` and `snapshot_folder_in_disk1`
    # so we expect nothing to be deleted.

    if is_snap_safe_to_del $snap $TEST_SUBS; then
        echo_err "Test failed!"
    else
        echo "APP: it is NOT SAFE to delete $snap!"
    fi
done < <( snapshots_in $TEST_SUBS )
echo_green "* Passed test."
