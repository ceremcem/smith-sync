#!/bin/bash


# ----------------------------------------------------
# -- Checklist
# ----------------------------------------------------
# * detect device to format
# * create appropriate partitions
# * format these partitions with appropriate filesystems
# * mount partitions
# * copy files from backup to these mountpoints
# * INSTALL APPROPRIATE BOOTLOADER (no need for RaspberryPi)
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/common.sh

get_device
for i in {5..1}; do
	echo "$DEVICE will be formatted in $i seconds..."
	sleep 1
done

echo "Creating partition table on ${DEVICE}..."
# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${DEVICE}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
  +300M # boot parttion
  t # change the type (1st partition will be selected automatically)
  83 # Changed type of partition to 'Linux'
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

echo "Creating ext2 filesystem for boot partition"
mkfs.ext2 "${DEVICE}1"

echo "Creating LUKS layer on ${DEVICE}2..."
cryptsetup -y -v luksFormat "${DEVICE}2"

decrypt_crypted_partition

echo "Creating LVM partitions"
pvcreate "/dev/mapper/$D_DEVICE" || echo_err "physical volume exists.."
vgcreate "${ROOT_NAME}" "/dev/mapper/$D_DEVICE" || echo_err "volume group exists.."
lvcreate -n swap -L 16G $ROOT_NAME
lvcreate -n root -l 100%FREE $ROOT_NAME

echo "Formatting swap and root (btrfs) partitions"
mkswap $SWAP_PART
mkfs.btrfs $ROOT_PART

echo "Removing LVM partitions and Cryptsetup device"
remove_parts

echo "done..."
