#!/bin/bash -xe

# create a random key file if not already existing
if [ ! -f "$ARTIFACTDIR/secret.txt" ]; then
  dd if=/dev/urandom bs=20 count=1 status=none | base64 > "$ARTIFACTDIR/secret.txt"
fi

# umount the partitions
umount -lf $ROOTDIR/boot $ROOTDIR

# minimize extent for rootfs filesystem (cryptsetup-reencrypt needs a 4096 sectors header)
resize2fs -fM /dev/vda2

# setup encryption
cat "$ARTIFACTDIR/secret.txt" | cryptsetup-reencrypt /dev/vda2 --new --reduce-device-size 4096S

# resize filesystem to fill up partition again
cat "$ARTIFACTDIR/secret.txt" | cryptsetup open /dev/vda2 crypt
resize2fs -f /dev/mapper/crypt

# remount partitions
mount /dev/mapper/crypt $ROOTDIR
mount /dev/vda1 $ROOTDIR/boot

# get root partition UUID
rootfs=`blkid -s UUID -o value /dev/vda2`

# create fstab
cat > $ROOTDIR/etc/fstab << EOF
/dev/mapper/crypt  /        ext4    defaults    0   1
LABEL=boot         /boot/   ext4    defaults    0   1
EOF

# create kernel cmdline
echo "cryptdevice=UUID=$rootfs:crypt root=/dev/mapper/crypt" > $ROOTDIR/etc/kernel/cmdline

# create crypttab
cat > $ROOTDIR/etc/crypttab << EOF
crypt  UUID=$rootfs  none  luks,initramfs
EOF

# update GRUB defaults
perl -i -p -e "s{(^GRUB_CMDLINE_LINUX_DEFAULT=.quiet)}{\\1 cryptdevice=UUID=$rootfs:crypt}" $ROOTDIR/etc/default/grub
perl -i -p -e "s/^#(GRUB_DISABLE_LINUX_UUID=true)/\\1/" $ROOTDIR/etc/default/grub
perl -i -p -e "s/^#(GRUB_DISABLE_RECOVERY=.true.)/\\1/" $ROOTDIR/etc/default/grub

# install GRUB
grub-install --target=i386-pc --boot-directory=$ROOTDIR/boot --recheck /dev/vda

# mount system dirs
for d in dev proc sys; do mount -o bind /$d $ROOTDIR/$d; done

# generate grub.cfg
chroot $ROOTDIR /usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg

# update the initramfs
chroot $ROOTDIR /usr/sbin/update-initramfs -u -k all

# umount system dirs
for d in dev proc sys; do umount -lf $ROOTDIR/$d; done
