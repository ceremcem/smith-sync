# BTRFS 
## Get profile info 

To see how BTRFS partition is configured, use the following command:

```
btrfs fi usage /mnt/foo
```

## Convert single setup to DUP 

This is useful if you have only one physical disk and you still want data redundancy to some degree:

```
btrfs balance start -v -dconvert=dup,soft /path/to/mountpoint 
```

To check and **fix** data on a disk with DUP profile, simply run `btrfs scrub`: 

```
btrfs scrub start -B /path/to/mountpoint
```

## Convert single setup to RAID1

> Based on https://btrfs.wiki.kernel.org/index.php/Using_Btrfs_with_Multiple_Devices#Conversion

Assuming your root btrfs subvolume is on an LVM partition (`/dev/mapper/foo-root`) on your primary disk (`/dev/sda`) is mounted on `/` and you want to add a partition (`/dev/mapper/foo2-root`) as RAID1, which is on an LVM (named: `foo2`) partition on a LUKS partition (`/dev/sdb2`).

> ## FINISH THIS HOWTO'S TESTS

Setup to automount your LUKS partition first:

```console
# mkdir /etc/luks-keys
# dd if=/dev/urandom of=/etc/luks-keys/sdb2.key bs=512 count=8
# chmod 600 /etc/luks-keys/*
# cryptsetup -v luksAddKey /dev/sdb2 /etc/luks-keys/sdb2.key 
Enter any existing passphrase: 
Key slot 0 unlocked.
Key slot 1 created.
Command successful.
# blkid | awk '$1 == "/dev/sdb2:" {print $2}'
# echo "foo2_crypt UUID=the-above-uuid-of-sdb2 /etc/luks-keys/sdb2.key luks" >> /etc/crypttab

# ----- Start of fail case -----
# # If computer is rebooted at this point, BTRFS will complain about missing device because 
# # cryptsetup doesn't know if it needs to open `/dev/sdb2` too in order to properly mount 
# # `foo-root` yet. If you open your system with a rescue disk and mount `foo-root` with `-o degraded`
# # or pass "degraded" option to the kernel inside GRUB (rootflags=degraded,...), you'll be able to 
# # mount your partition IN RW MODE, BUT ONLY ONCE. If you can't fix the "missing device issue, 
# # you'll end up with a BTRFS file system that can only be mounted with `-o degraded,ro` option. 
# # From this point on, your only option (except backing up the files, recreating the fs and restoring 
# # your files back) is making `foo-root` partition available (decrypt `/dev/sda2` and lvscan) 
# # and mounting the other device (`foo2-root` on `/dev/sdb2`) to a directory (`/mnt/foo_raid1`). 
# # Run `btrfs fi usage /mnt/foo_raid1` and if you see any "Single" and/or "DUP" data, run the following
# #
# #     btrfs balance start -dconvert=raid1 -mconvert=raid1 /mnt/foo_raid1
# # 
# ----- End of fail case -----




cryptroot/crypttab ??? (only one entry)





# update-initramfs -u  # TODO: TEST THIS!!!
```

Add the partition as RAID1:
```
cryptsetup open /dev/sdb2 foo2_crypt
lvscan 
btrfs device add /dev/mapper/foo2-root /
btrfs balance start -dconvert=raid1 -mconvert=raid1 /
```

# Monitoring Disk Health 

See https://github.com/ceremcem/monitor-btrfs-disk

## Hotplugging SATA Disk

Enable "Hot Plug" option in BIOS for each SATA port. (https://unix.stackexchange.com/questions/368958/sata-hotplug-doesnt-work)

# Restoring Files 

```
btrfs restore -s /dev/mapper/foo-root --path-regex ^(|/rootfs.bak(|/var(|/lib(|/couchdb(|/shards(|/60000000-7fffffff(|/.*)))))))$ /mnt/backup-disk/hello/
```

* `-s`: Enable subvolumes
* `rootfs.bak`: The subvolume we want to search inside.
