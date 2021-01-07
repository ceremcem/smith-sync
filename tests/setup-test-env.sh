#!/bin/bash

truncate -s 100M ./btrfs_src
truncate -s 100M ./btrfs_tgt
lo_src=$(losetup -f)
losetup $lo_src ./btrfs_src
lo_tgt=$(losetup -f)
losetup $lo_tgt ./btrfs_tgt
mkfs.btrfs $lo_src
mkfs.btrfs $lo_tgt
mkdir mnt_src
mkdir mnt_tgt
mount $lo_src ./mnt_src
mount $lo_tgt ./mnt_tgt

