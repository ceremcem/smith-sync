# BTRFS 
## Get profile info 

```
btrfs fi usage /mnt/foo
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

## Check corrupted files 

Following command will read and write every file on the mountpoint (warning: it will take too long)

```
sudo btrfs balance start /mnt/peynir/
```

# Hardware Related 

## Determine Disk Health 

```
sudo smartctl -x /dev/sdX
```

## Hotplug SATA 

> TO BE TESTED

https://unix.stackexchange.com/questions/368958/sata-hotplug-doesnt-work

