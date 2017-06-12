
DEBUG=true
echo "Deleting all snapshots in $TEST_FOLDER"
while read -a snap; do
    if is_snap_safe_to_del $snap $TEST_SUBS; then
        echo "APP: it is safe to delete $snap"
        echo btrfs sub delete $snap
        debug_step
        btrfs sub delete $snap
    else
        echo "APP: it is NOT SAFE to delete $snap!"
    fi
done < <( snapshots_in $TEST_FOLDER )


# Only $TEST_SUBS/a-3 should be left
while read -a f; do
    if [[ "$f" != "$TEST_FOLDER/a-3" ]]; then
        echo_err "Test Failed!"
    fi
done < <( find $TEST_FOLDER -maxdepth 1 -mindepth 1 )
echo_green "* Passed test."
