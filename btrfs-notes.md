# Get profile info 

```
btrfs fi usage /mnt/foo
```

# Convert single setup to RAID1

> Based on https://btrfs.wiki.kernel.org/index.php/Using_Btrfs_with_Multiple_Devices#Conversion

Assuming your root btrfs subvolume on your primary disk (`/dev/sda2`) is mounted on `/mnt/foo` and you want to add a btrfs partition (`/dev/mapper/bar-root`) as RAID1, which is on an LVM partition which is on a LUKS partition (`/dev/sdb2`):

```
cryptsetup open /dev/sdb2 bar
lvscan 
btrfs device add /dev/mapper/bar-root /mnt/foo
btrfs balance start -dconvert=raid1 -mconvert=raid1 /mnt/foo
```

### PROBLEM: This operation might end up with readonly filesystem. 

