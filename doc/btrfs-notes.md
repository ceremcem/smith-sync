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

Assuming your root btrfs subvolume on your primary disk (`/dev/sda2`) is mounted on `/mnt/foo` and you want to add a btrfs partition (`/dev/mapper/bar-root`) as RAID1, which is on an LVM partition which is on a LUKS partition (`/dev/sdb2`):

```
cryptsetup open /dev/sdb2 bar
lvscan 
btrfs device add /dev/mapper/bar-root /mnt/foo ##### <- warning at the moment this will fail with READONLY filesystem
btrfs balance start -dconvert=raid1 -mconvert=raid1 /mnt/foo
```

# Monitoring Disk Health 

See https://github.com/ceremcem/monitor-btrfs-disk

## Hotplugging SATA Disk

Enable "Hot Plug" option in BIOS for each SATA port. (https://unix.stackexchange.com/questions/368958/sata-hotplug-doesnt-work)

# Restoring Files 

```
btrfs restore -s /dev/mapper/foo-root --path-regex ^(|/rootfs.bak(|/var(|/lib(|/couchdb(|/shards(|/60000000-7fffffff(|/.*)))))))$ /mnt/backup-disk/hello/
```

`-s`: Enable subvolumes
`rootfs.bak`: The subvolume we want to search inside.
