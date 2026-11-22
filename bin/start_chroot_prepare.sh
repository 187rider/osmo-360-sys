#!/bin/sh
echo $PATH >> /dev/kmsg

echo "<3> [test] Init to start_chroot_prepare" >> /dev/kmsg

SYSTEM_SLOT="system${SLOT_SUFFIX}"
chmod 777 /bin/mount.util-linux
mount -o remount,dev,suid /$SYSTEM_SLOT

mount --bind /dev /$SYSTEM_SLOT/dev
mount --bind /sys /$SYSTEM_SLOT/sys
mount --bind /run /$SYSTEM_SLOT/run
mount --bind /proc /$SYSTEM_SLOT/proc
mount --bind /dev/pts /$SYSTEM_SLOT/dev/pts
mount --bind /dev/binderfs /$SYSTEM_SLOT/dev/binderfs
mount --bind /dev/socket /$SYSTEM_SLOT/dev/socket
mkdir /$SYSTEM_SLOT/run/udev
mount --bind /run/udev /$SYSTEM_SLOT/run/udev
mount --bind /sys/kernel/debug /$SYSTEM_SLOT/sys/kernel/debug

export PATH=/bin:/sbin:/usr/bin:/usr/sbin
touch /dev/.chroot_prepare_done

echo "<3> [test]: start_chroot_prepare end. " >> /dev/kmsg
