#!/bin/bash

# pre-requisites

[[ ! `sudo secon -r` == 'unconfined_r' ]] && echo "needs root/sysadm.role" 	&& exit 1
[[ ! -e /usr/bin/systemd-run ]] 		  && echo "need /usr/bin/systemd-run" && exit 1
 
# Ensure that the essential mount points are available in the LAYER
LAYER="${HOME}/LAYER"
mkdir -p "$LAYER/var" "$LAYER/etc" "$LAYER/usr" "$LAYER/.work-usr" "$LAYER/.work-var" "$LAYER/.work-etc"

# Ensure that the essential mount points are available in the CHROOT
CHROOT=$(mktemp -d)
mkdir -p "$CHROOT/host" "$CHROOT/var" "$CHROOT/usr" "$CHROOT/boot" "$CHROOT/etc"
ln -s /host/usr/bin $CHROOT/bin
ln -s /host/usr/lib $CHROOT/lib
ln -s /host/usr/lib64 $CHROOT/lib64
ln -s /host/usr/sbin $CHROOT/sbin
ln -s /var/home $CHROOT/home
ln -s /var/mnt $CHROOT/mnt
ln -s /var/opt $CHROOT/opt
ln -s /var/root $CHROOT/root
ln -s /var/srv $CHROOT/srv # may leave srv out of it

trap "{ sudo umount $CHROOT/usr $CHROOT/var $CHROOT/etc; sudo rm -rf '$CHROOT';}" EXIT

sudo mount -t overlay overlay -o lowerdir=/usr,upperdir=$LAYER/usr,workdir=$LAYER/.work-usr $CHROOT/usr
sudo mount -t overlay overlay -o lowerdir=/var,upperdir=$LAYER/var,workdir=$LAYER/.work-var $CHROOT/var
sudo mount -t overlay overlay -o lowerdir=/etc,upperdir=$LAYER/etc,workdir=$LAYER/.work-etc $CHROOT/etc
 
sudo --preserve-env systemd-run \
    -p Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    -p Environment=HOME=/root \
    -p RootDirectory="$CHROOT" \
    -p MountAPIVFS=yes \
    -p BindReadOnlyPaths='/:/host:norbind /boot' \
    -p BindPaths="$HOME:/root" \
    -p PrivateTmp=yes \
    -t /bin/bash --rcfile /etc/bash.in.pkg.rc
