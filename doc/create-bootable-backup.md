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

       sudo grub-install --boot-directory=/mnt/target-boot /dev/sdX    

5. Change the configuration in `boot/grub/grub.cfg`: 
    1. Change root partition UUID's and LVM names in "linux..." line accordingly

           linux	/vmlinuz-4.9.0-7-amd64 root=/dev/mapper/zeytin-root resume=/dev/mapper/zeytin-swap ro rootflags=subvol=rootfs cryptopts=source=UUID=ef966229-c382-4c8a-97bf-e413e8826d9e,target=zeytin_crypt,lvm=zeytin-root 

      where `ef96-...-6d9e` is the output of `sudo blkid | grep sdX | grep crypto_LUKS`.
      

    2. change boot partition's UUID:

           --set=root the-uuid-of-boot-partition

6. Change `etc/fstab` entries accordingly
7. Change `etc/crypttab` entries accordingly
8. Update `/etc/initramfs-tools/conf.d/resume` according to `grep swap /etc/fstab` output
9. *Optional*: If this will be a diverged clone, [give-new-id](https://github.com/aktos-io/dcs-tools/blob/master/give-new-id).

# Important 

If everything above goes well and **you have booted up with your new disk**, continue reading.

Above procedure is sufficient for booting up from a newly formatted LUKS partition. However, when you directly or indirectly invoke `update-grub` for some reason (system upgrades, changing initramfs static IP, etc.), you will be end up with **unbootable system**. It's highly recommended to take appropriate measures against `/boot/grub/grub.cfg` overwrites: 

### Prepare the failsafe backup

1. `cp /boot/grub/grub.cfg /boot/grub/grub.cfg.failsafe`
2. If anything goes wrong, load failsafe config file in the grub shell manually:

       grub> configfile (hd0,msdos1)/boot/grub/grub.cfg.failsafe


### Add appropriate boot options 

1. Declare your above extra arguments (`cat /proc/cmdline | tr ' ' '\n'`) in `/etc/default/grub` file: 

       GRUB_CMDLINE_LINUX="\
               resume=/dev/mapper/zeytin-swap \
               rootflags=subvol=rootfs \
               cryptopts=source=UUID=ef966229-c382-4c8a-97bf-e413e8826d9e,target=zeytin_crypt,lvm=zeytin-root"
               
2. Update Grub

       sudo update-grub 
       
3. Optionally check the difference between newly created `grub.cfg` and `grub.cfg.failsafe`

4. Reboot

5. See you can still succesfully boot up. 
