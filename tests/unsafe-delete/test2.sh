
echo "Deleting all snapshots in $TEST_SUBS"
while read -a snap; do
    if is_snap_safe_to_del $snap $TEST_FOLDER; then
        echo "APP: it is safe to delete $snap"
        btrfs sub delete $snap
    else
        echo "APP: it is NOT SAFE to delete $snap!"
    fi
done < <( snapshots_in $TEST_SUBS )


# Test conditions
# Only $TEST_SUBS/a-3 should be left
while read -a f; do
    if [[ "$f" != "$TEST_SUBS/a-3" ]]; then
        echo_err "Test Failed!"
    fi
done < <( snapshots_in $TEST_SUBS )
echo_green "* Passed test."
