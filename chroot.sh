#!/usr/bin/bash

set -eux

echo "Setting up locale and timezone"
#ln -sf /usr/share/zoneinfo/Australia/Sydney /etc/localtime
hwclock --systohc
sed -i '/fr_FR.UTF-8/s/#//' /etc/locale.gen
locale-gen
#echo LANG=en_AU.UTF-8 > /etc/locale.conf
echo "FONT=lat9w-16" > /etc/vconsole.conf

echo "Setting up networking"
#echo "archvm$(date +%Y%m%d)" > /etc/hostname
echo "127.0.0.1   localhost
::1         localhost
127.0.1.1   archvm.localdomain archvm" > /etc/hosts
systemctl enable systemd-{resolve,network}d.service
echo "[Match]
Name=en*

[Network]
DHCP=yes" > /etc/systemd/network/20-wired.network

echo "Setting up NTP"
systemctl enable systemd-timesyncd.service
timedatectl set-ntp true

#echo "Setting up swap"
## TODO: This isn't idempotent, and fails on second run.
#dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
#chmod 600 /swapfile
#mkswap /swapfile
#swapon /swapfile
#echo "/swapfile none swap defaults 0 0" >> /etc/fstab

#echo "Installing extra packages"
## These packages are the minimum needed for rebooting, connecting via SSH, and
## git cloning additional setup scripts as a non-root user.
#pacman --noconfirm -S dhcpcd openssh sudo git
#systemctl enable dhcpcd.service
#systemctl enable sshd.service

echo "Configuring initramfs (mkinitcpio) and creating unified kernel image"
# Configure systemd-based initramfs
sed -i "/^HOOKS/s/base udev/systemd/" /etc/mkinitcpio.conf
# Configure mkinitcpio to generate a unified kernel image with stub loader
# this allows us to forego both fstab and kernel command line
echo '# mkinitcpio preset file for the '\''linux'\'' package

ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('\''default'\'')

default_image="/boot/initramfs-linux.img"
default_efi_image="/boot/archlinux-linux.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"' > /etc/mkinitcpio.d/linux.preset
# required to prevent copying of current /proc/cmdline
touch /etc/kernel/cmdline
mkinitcpio -P

echo "Creating user"
NAME=archvm
useradd -m -G wheel -s /bin/zsh "${NAME}"
echo "${NAME}":"${NAME}" | chpasswd
printf "${NAME} ALL=(ALL) ALL\nDefaults timestamp_timeout=10\n" > /etc/sudoers.d/local
passwd -l root

echo "Creating UEFI boot entry"
efibootmgr  --create --disk /dev/vda --part 1 --label "Arch Linux" --loader /archlinux-linux.efi --verbose
