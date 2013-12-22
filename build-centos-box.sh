#!/bin/bash -ex

# Build a new CentOS6 install in a chroot
# Loosely based on http://wiki.1tux.org/wiki/Centos6/Installation/Minimal_installation_using_yum

BASHTONVER=1
releasever=6.5
arch=x86_64
ROOTFS=/rootfs
PARTITION=/rootfs.loop
SIZE=5G

# Install build/upload pre-requisites
yum -y install http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm

fallocate -l $SIZE ${PARTITION}
mkfs.ext4 -F -L / ${PARTITION}
tune2fs -c 0 -i 0 ${PARTITION}
mkdir -p $ROOTFS
mount -o loop $PARTITION $ROOTFS


### Basic CentOS Install
rpm --root=$ROOTFS --initdb
rpm --root=$ROOTFS -ivh \
  http://mirror.centos.org/centos/6.5/os/x86_64/Packages/centos-release-6-5.el6.centos.11.1.x86_64.rpm
# Install necessary packages
yum --installroot=$ROOTFS --nogpgcheck -y groupinstall base core
yum --installroot=$ROOTFS --nogpgcheck -y install redhat-lsb-core

# Create homedir for root
cp -a /etc/skel/.bash* ${ROOTFS}/root

## Networking setup
cat > ${ROOTFS}/etc/hosts << END
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

127.0.1.1   centos6
END
cat > ${ROOTFS}/etc/sysconfig/network << END
NETWORKING=yes
HOSTNAME=centos6
END
cat > ${ROOTFS}/etc/sysconfig/network-scripts/ifcfg-eth0  << END
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
END

cp /usr/share/zoneinfo/UTC ${ROOTFS}/etc/localtime

echo 'ZONE="UTC"' > ${ROOTFS}/etc/sysconfig/clock

# fstab
cat > ${ROOTFS}/etc/fstab << END
LABEL=/ /         ext4    defaults,relatime  1 1
tmpfs   /dev/shm  tmpfs   defaults           0 0
devpts  /dev/pts  devpts  gid=5,mode=620     0 0
sysfs   /sys      sysfs   defaults           0 0
proc    /proc     proc    defaults           0 0
END

#grub config
KERNELVER=$(rpm --root=${ROOTFS} -qa | grep '^kernel-2.6.32' | sed -e 's/kernel-//')
cat > ${ROOTFS}/boot/grub/grub.conf << END
default=0
timeout=1
hiddenmenu
title CentOS $releasever bashton${BASHTONVER}
  root (hd0)
  kernel /boot/vmlinuz-${KERNELVER} ro root=LABEL=/ console=hvc0 xen_blkfront.sda_is_xvda=1 rd_NO_LUKS LANG=en_US.UTF-8 rd_NO_MD KEYTABLE=us
  initrd /boot/initramfs-${KERNELVER}.img
END
cp ${ROOTFS}/boot/grub/grub.conf ${ROOTFS}/boot/grub/menu.lst

# Basic /dev nodes
for type in console null zero urandom ; do
  /sbin/MAKEDEV -d ${ROOTFS}/dev -x $type
done

#Disable SELinux
sed -i -e 's/^\(SELINUX=\).*/\1disabled/' ${ROOTFS}/etc/selinux/config
### End basic CentOS Install

## Extra packages needed for cloud-init/AWS tools
yum --installroot=$ROOTFS --nogpgcheck -y install nc acpid python-cheetah python-configobj

# AMI additions
for file in \
  http://www.bashton.com/downloads/centos-ami/RPMS/noarch/ec2-utils-0.4-1.19.el6_bashton1.noarch.rpm \
  http://www.bashton.com/downloads/centos-ami/RPMS/noarch/ec2-net-utils-0.4-1.19.el6_bashton1.noarch.rpm \
  http://dl.fedoraproject.org/pub/epel/6/x86_64/python-boto-2.13.3-1.el6.noarch.rpm \
  http://dl.fedoraproject.org/pub/epel/6/x86_64/libyaml-0.1.3-1.el6.x86_64.rpm \
  http://dl.fedoraproject.org/pub/epel/6/x86_64/PyYAML-3.10-3.el6.x86_64.rpm \
  http://www.bashton.com/downloads/centos-ami/RPMS/noarch/cloud-init-0.5.15-75.el6_bashton1.noarch.rpm ; do
  wget $file
  yum --installroot=$ROOTFS --nogpgcheck -y localinstall $(basename $file)
  rm $(basename $file)
done
sed -i -e 's/^\(PasswordAuthentication\) yes/\1 no/' /etc/ssh/sshd_config

# fingerprint daemon causes errors - makes no sense to have it on 'cloud'
yum --installroot=$ROOTFS --nogpgcheck -y remove fprintd libfprint fprintd-pam
rm ${ROOTFS}/etc/pam.d/fingerprint*

umount ${ROOTFS}
