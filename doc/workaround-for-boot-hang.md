# Boot hangs while creating volatile files

Sometimes, on Debian system, boot process hangs with following message: 

    A start job is running for Create Volatile Files and Directories.

Workaround is as follows:

1. Boot with initramfs param in GRUB: `break=bottom`

2. On initramfs console:

        mount -o rw,remount /root
        cd /root
        mv tmp tmp.bak
        mkdir tmp
        chmod 1777 tmp
        chattr +C tmp   # good for BTRFS
        reboot
        (you may delete /tmp.bak later)


