if is_snap_safe_to_del $TEST_FOLDER/a-1 $TEST_SUBS; then
    echo "APP: it is safe to delete snapshot"
else
    echo "APP: it is NOT SAFE to delete this snapshot!"
fi
