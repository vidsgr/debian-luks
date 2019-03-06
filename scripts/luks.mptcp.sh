#!/bin/bash -xe

# create a random key file if not already existing
if [ ! -f "$ARTIFACTDIR/secret.txt" ]; then
  dd if=/dev/urandom bs=80 count=1 status=none | base64 --wrap=0 > "$ARTIFACTDIR/secret.txt"
fi

# umount the partitions
umount -lf $ROOTDIR/boot $ROOTDIR

# minimize extent for rootfs filesystem (cryptsetup-reencrypt needs a 4096 sectors header)
resize2fs -fM /dev/vda2
mkswap /dev/vda3

# setup encryption
cat "$ARTIFACTDIR/secret.txt" | cryptsetup-reencrypt /dev/vda2 --new --reduce-device-size 8192S --key-size 512 --hash sha512


# resize filesystem to fill up partition again
cat "$ARTIFACTDIR/secret.txt" | cryptsetup open /dev/vda2 crypt
resize2fs -f /dev/mapper/crypt

# remount partitions
mount /dev/mapper/crypt $ROOTDIR
mount /dev/vda1 $ROOTDIR/boot

cp $ARTIFACTDIR/secret.txt $ROOTDIR/boot/crypt.key
chmod 0400 $ROOTDIR/boot/crypt.key
cat "$ARTIFACTDIR/secret.txt" | cryptsetup luksAddKey /dev/vda2 $ROOTDIR/boot/crypt.key

# get root partition UUID
rootfs=`blkid -s UUID -o value /dev/vda2`
boot=`blkid -s UUID -o value /dev/vda1`

# create fstab
cat > $ROOTDIR/etc/fstab << EOF
/dev/mapper/crypt  /        ext4    defaults,noatime    0   1
LABEL=boot         /boot/   ext4    defaults,noatime    0   1
LABEL=swap                   swap    swap                0   0
EOF

# create kernel cmdline
echo "cryptdevice=UUID=$rootfs:crypt root=/dev/mapper/crypt" > $ROOTDIR/etc/kernel/cmdline

#crypt  UUID=$rootfs  none  luks,initramfs
#crypt  UUID=$rootfs  /dev/disk/by-uuid/$boot:/crypt.key  luks,initramfs,keyscript=/lib/cryptsetup/scripts/passdev

#crypt  UUID=$rootfs  /dev/disk/by-uuid/$boot:/crypt.key  luks,keyscript=/lib/cryptsetup/scripts/passdev
# create crypttab
cat > $ROOTDIR/etc/crypttab << EOF
crypt  UUID=$rootfs  /dev/disk/by-uuid/$boot:/crypt.key  luks,keyscript=/lib/cryptsetup/scripts/passdev
EOF

cat > $ROOTDIR/etc/initramfs-tools/hooks/crypto_keyfile <<EOF
#!/bin/bash
if [ "$1" = "prereqs" ] ; then
    cp /boot/crypt.key "${DESTDIR}"
fi
EOF
chmod a+x $ROOTDIR/etc/initramfs-tools/hooks/crypto_keyfile

# update GRUB defaults
perl -i -p -e "s{(^GRUB_CMDLINE_LINUX_DEFAULT=.quiet)}{\\1 cryptdevice=UUID=$rootfs:crypt fbcon=map:99  console=ttyS0,115200n8}" $ROOTDIR/etc/default/grub
perl -i -p -e "s/^#(GRUB_DISABLE_LINUX_UUID=true)/\\1/" $ROOTDIR/etc/default/grub
perl -i -p -e "s/^#(GRUB_DISABLE_RECOVERY=.true.)/\\1/" $ROOTDIR/etc/default/grub
perl -i -p -e "s/^#(GRUB_TERMINAL=serial)/\\1/" $ROOTDIR/etc/default/grub

#mkdir $ROOTDIR/backup
#cp -r $ROOTDIR/boot/*mptcp* $ROOTDIR/backup
#chroot $ROOTDIR rm -rf $ROOTDIR/boot/config-*
#chroot $ROOTDIR rm -rf $ROOTDIR/boot/initrd*
#chroot $ROOTDIR rm -rf $ROOTDIR/boot/System.map-*
#cp -r $ROOTDIR/backup/*mptcp* $ROOTDIR/boot/
#rm -rf $(ls -d $ROOTDIR/lib/modules/*| grep -v mptcp)
#rm -rf $ROOTDIR/backup
#rm $ROOTDIR/boot/grub/grub.cfg 

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
