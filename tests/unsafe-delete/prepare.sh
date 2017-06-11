
btrfs sub create $TEST_SUBS/a

for snap in 1 2 3; do
    echo "Creating snapshot"
    echo $(date +%s%N) | tee "$TEST_SUBS/a/mytest.txt"
    take_snapshot $TEST_SUBS/a "$TEST_SUBS/a-$snap"
done

while read -a src; do
    echo "* sending $src to $TEST_FOLDER"
    btrfs send $src | btrfs receive $TEST_FOLDER
done < <(snapshots_in $TEST_SUBS)
