#!/usr/bin/bash

set -eux

notice() {
	set +x
	printf '\e[32m%s\n\e[0m' "$@"
	set -x
}

notice "Setting up locale and timezone."
#ln -sf /usr/share/zoneinfo/Australia/Sydney /etc/localtime
hwclock --systohc
sed -i '/fr_FR.UTF-8/s/#//' /etc/locale.gen
locale-gen
#echo LANG=en_AU.UTF-8 > /etc/locale.conf
echo "FONT=lat9w-16" > /etc/vconsole.conf

notice "Setting up networking."
#echo "archvm$(date +%Y%m%d)" > /etc/hostname
echo "127.0.0.1   localhost
::1         localhost
127.0.1.1   archvm.localdomain archvm" > /etc/hosts
systemctl enable systemd-{resolve,network}d.service
echo "[Match]
Name=en*

[Network]
DHCP=yes" > /etc/systemd/network/20-wired.network

notice "Setting up NTP."
systemctl enable systemd-timesyncd.service
timedatectl set-ntp true

#notice "Setting up swap."
## TODO: This isn't idempotent, and fails on second run.
#dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
#chmod 600 /swapfile
#mkswap /swapfile
#swapon /swapfile
#echo "/swapfile none swap defaults 0 0" >> /etc/fstab

#notice "Installing extra packages."
## These packages are the minimum needed for rebooting, connecting via SSH, and
## git cloning additional setup scripts as a non-root user.
#pacman --noconfirm -S dhcpcd openssh sudo git
#systemctl enable dhcpcd.service
#systemctl enable sshd.service

notice "Configuring initramfs (mkinitcpio)"
sed -i "/^HOOKS=(base udev/s/base udev/systemd/" /etc/mkinitcpio.conf
sed -i "/PRESETS=('default' 'fallback')/s/ 'fallback'//" /etc/mkinitcpio.d/linux.preset
mkinitcpio -P

notice "Creating user."
NAME=archvm
useradd -m -G wheel -s /bin/zsh "${NAME}"
echo "${NAME}":"${NAME}" | chpasswd
printf "${NAME} ALL=(ALL) ALL\nDefaults timestamp_timeout=10\n" > /etc/sudoers.d/local
passwd -l root

# Use direct EFISTUB booting
notice "Creating UEFI boot entry"
efibootmgr --disk /dev/vda --part 1 --create --label "Arch Linux" --loader /vmlinuz-linux --unicode 'root=/dev/vda2 rw initrd=\initramfs-linux.img' --verbose
