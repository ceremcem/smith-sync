# Simple Example for `switch_root`

This is the simplest possible `init` file that demonstrates `switch_root` usage: 

```bash
# First, find and mount the new filesystem.

mkdir /newroot
mount /dev/whatever /newroot

# Unmount everything else you've attached to rootfs.  (Moving the filesystems
# into newroot is something useful to do with them.)

mount --move /sys /newroot/sys
mount --move /proc /newroot/proc
mount --move /dev /newroot/dev

# Now switch to the new filesystem, and run /sbin/init out of it.  Don't
# forget the "exec" here, because you want the new init program to inherit
# PID 1.

exec switch_root /newroot /sbin/init
```