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

To check and fix data: 

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

## Find the corrupted files 

Output is instantaneous after `btrfs scrub`, however paths are relative to their subvolumes, thus it's hard to identify which file belongs to which subvolume:

```
##sudo btrfs scrub start -B /path/to/mountpoint # -> you should already have done that
sudo journalctl --output cat | grep 'BTRFS .* i/o error' | sort | uniq > corrupted-files.txt
```

> See https://unix.stackexchange.com/q/557213/65781 for updates of this problem

Following command takes a long time but gives the exact paths:

```
sudo find / -type f -and -not -path /proc -exec cp -v {} /dev/null \; 2> corrupted-files.txt
```

To monitor the corrupted files log:

```
watch cat corrupted-files.txt
```

# Hardware Related 

## Determine Disk Health 

#### 1. Physical health: 

```
sudo smartctl -t long -C /dev/sdX
sudo badblocks -v /dev/sdX
```

TODO: Document how to interpret the `smartctl` results. 

##### 2. Data integrity check: 

Do the following periodically (once a month to once a week):

```
btrfs scrub start -B /path/to/mountpoint
```

See https://github.com/ceremcem/monitor-btrfs-disk

##### 3. "DRDY ERR" check:

```
sudo dmesg | grep "DRDY ERR"
```


## Hotplugging SATA Disk

> TO BE TESTED

https://unix.stackexchange.com/questions/368958/sata-hotplug-doesnt-work

