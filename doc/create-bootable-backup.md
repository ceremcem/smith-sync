# Create Bootable Backup Disk 

Assuming your disk layout is as follows: 

1. `/boot` partition is on 1th partition (`/dev/sdX1`)
2. `/` and `swap` partitions are on LVM on LUKS partition which is on 2nd partition of the disk (`/dev/sdX2`)

Given that, when you want to create a bootable backup disk, follow these steps:

1. Format a new disk and create appropriate disk layout (use [a formatter script](https://github.com/ceremcem/erik-sync/blob/a3c9af2bab28409ae4a42bcacf13dbcf699d98fc/format-new-erik.sh), target name is `zeytin` in this example)
2. Sync `/`
       
       # use btrfs or rsync, according to your setup 
       
3. Sync `/boot`

       mount /dev/sdX1 /mnt/target-boot
       rsync -avP /boot/ /mnt/target-boot/

4. Install GRUB to target disk:

       sudo grub-install --boot-directory=/mnt/target-boot /dev/sdX    

5. Change the configuration in `boot/grub/grub.cfg`: 
    1. Change root partition UUID's and LVM names in "linux..." line accordingly

           linux	/vmlinuz-4.9.0-7-amd64 root=/dev/mapper/zeytin-root resume=/dev/mapper/zeytin-swap ro rootflags=subvol=rootfs cryptopts=source=UUID=HELLO,target=zeytin_crypt,lvm=zeytin-root 

      where `HELLO` is the output of `sudo blkid | grep sdX | grep crypto_LUKS`.
      

    2. change boot partition's UUID, where `HI_THERE` is the "UUID" value of output of `sudo blkid | grep sdX1`:

           --set=root HI_THERE

6. Change `etc/fstab` entries accordingly
7. Change `etc/crypttab` entries accordingly
8. Update `/etc/initramfs-tools/conf.d/resume` according to `grep swap /etc/fstab` output
9. *Optional*: If this will be a diverged clone, [give-new-id](https://github.com/aktos-io/dcs-tools/blob/master/give-new-id).
10. Boot up with your new disk.
11. Continue from below **Important** section.

# Important 

If everything above went well and **you have booted up with your new disk**, continue reading. If you haven't rebooted yet, do not continue, because some operations below rely on *current* kernel parameters.

Above procedure (till `#10`) is sufficient for booting up from a newly formatted LUKS partition. However, when you directly or indirectly invoke `update-grub` for some reason (system upgrades, changing initramfs static IP, etc.), you will be end up with **unbootable system**. It's highly recommended to take appropriate measures against `/boot/grub/grub.cfg` overwrites: 

### Make GRUB parameters persistent

1. Backup your current `grub.cfg` just in case:

       cp /boot/grub/grub.cfg /boot/grub/grub.cfg.failsafe
       
2. Be prepared to load above backup config file inside the grub shell manually. Remember the following to use backup config:

       grub> configfile (hd0,msdos1)/boot/grub/grub.cfg.failsafe

3. Make above GRUB changes persistent: 

    1. Edit `/etc/default/grub` file to add the required arguments (`cat /proc/cmdline | tr ' ' '\n'`): 

           GRUB_CMDLINE_LINUX="\
                   resume=/dev/mapper/zeytin-swap \
                   rootflags=subvol=rootfs \
                   cryptopts=source=UUID=HELLO,target=zeytin_crypt,lvm=zeytin-root"

    2. Update GRUB:

           [[ -f /boot/grub/grub.cfg.failsafe ]] || echo "Check your failsafe!" && sudo update-grub

    3. Optionally check the difference between newly created `grub.cfg` and `grub.cfg.failsafe` and verify your settings:

           git diff /boot/grub/grub.cfg.failsafe /boot/grub/grub.cfg

4. Reboot
