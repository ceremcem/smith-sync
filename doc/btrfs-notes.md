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
sudo btrfs scrub start -B /path/to/mountpoint # -> you should already have done that
./get-corrupted-files.sh
```

`get-corrupted-files.sh`: 

```sh
#!/bin/bash

sub_list=/tmp/subvolume-list-of-root.txt

sudo btrfs sub list / > $sub_list

while read a; do
    root_id=$(echo $a | awk '{print $16}' | sed -r 's/,//')
    rel_path=$(echo $a | sed -r 's/.*path:\s(.+)\)/\1/g')
    subvol_path=$(cat $sub_list | awk '$2 == '"$root_id"' {print $9}')
    [[ -z $subvol_path ]] && subvol_path="????"
    echo "/$subvol_path/$rel_path"
done < <( sudo journalctl --output cat | grep 'BTRFS .* i/o error' | sort | uniq )
```



> See also https://unix.stackexchange.com/q/557213/65781

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

