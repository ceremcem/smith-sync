# Create Bootable Backup Disk 

Assuming your disk layout is as follows: 

1. `/boot` partition is on 1th partition 
2. `/` and `swap` partitions are on LVM on LUKS partition which is on 2nd partition of the disk 

Given that, when you want to create a bootable backup disk, follow these steps:

1. Format a new disk and create appropriate disk layout (use [a formatter script](https://github.com/ceremcem/erik-sync/blob/a3c9af2bab28409ae4a42bcacf13dbcf699d98fc/format-new-erik.sh), target name is `zeytin` in this example)
2. Sync rootfs 
3. Sync /boot

       mount /dev/sdX1 /mnt/target-boot
       rsync -avP /boot/ /mnt/target-boot/

4. Install GRUB to target disk:

       sudo grub-install --boot-directory=/mnt/target-boot/grub /dev/sdX    

5. Change the configuration in `boot/grub/grub.cfg`: 
    1. Change root partition UUID's and LVM names in "linux..." line accordingly

           linux	/vmlinuz-4.9.0-7-amd64 root=/dev/mapper/zeytin-root resume=/dev/mapper/zeytin-swap ro rootflags=subvol=rootfs cryptopts=source=UUID=ef966229-c382-4c8a-97bf-e413e8826d9e,target=zeytin_crypt,lvm=zeytin-root 

      where `ef96-...-6d9e` is the output of `sudo blkid | grep sdX | grep crypto_LUKS`.
      

    2. change boot partition's UUID:

           --set=root the-uuid-of-boot-partition

6. Change `etc/fstab` entries accordingly
7. Change `etc/crypttab` entries accordingly
8. If this will be a diverged clone, [give-new-id](https://github.com/aktos-io/dcs-tools/blob/master/give-new-id).
