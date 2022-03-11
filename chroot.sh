#!/usr/bin/bash

set -eux

echo "Setting up locale and console font"
hwclock --systohc
sed -i '/fr_FR.UTF-8/s/#//' /etc/locale.gen
locale-gen
echo "FONT=ter-122b" > /etc/vconsole.conf

echo "Setting up networking"
cat << EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   archvm.localdomain archvm"
EOF
systemctl enable systemd-{resolve,network}d.service
cat << 'EOF' > /etc/systemd/network/20-wired.network
[Match]
Name=en*

[Network]
DHCP=yes
EOF

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
cat << EOF > /etc/mkinitcpio.d/linux.preset
# mkinitcpio preset file for the 'linux' package

ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default')

default_image="/boot/initramfs-linux.img"
default_efi_image="/boot/archlinux-linux.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"
EOF
# smooth splash image boot
echo "quiet bgrt_disable" > /etc/kernel/cmdline
mkinitcpio -P

echo "Creating user"
NAME=archvm
useradd -m -G wheel -s /bin/zsh "${NAME}"
echo "${NAME}":"${NAME}" | chpasswd
echo -e "${NAME} ALL=(ALL) ALL\nDefaults timestamp_timeout=10" > /etc/sudoers.d/local
passwd -l root

echo "Creating UEFI boot entry"
efibootmgr  \
    --create \
    --disk /dev/vda \
    --part 1 \
    --label "Arch Linux" \
    --loader /archlinux-linux.efi \
    --verbose

echo "pacman configuration"
# https://man.archlinux.org/man/pacman.conf.5.en#OPTIONS
sed -i \
    -e '/Color/s/#//' \
    -e '/VerbosePkgLists/s/#//' \
    -e '/Parallel/s/#//' \
    -e '/Parallel/ a ILoveCandy' \
    /etc/pacman.conf

echo "makepkg configuration"
# https://wiki.archlinux.org/title/Makepkg#Tips_and_tricks
# Enable native processor optimizations, as many parallel make jobs as there are logical
# cores and multi-threaded compression
sed -i \
    -e 's/x86-64 -mtune=generic/native/' \
    -e 's/#RUST/RUST/' \
    -e '/^RUST/s/"$/ -C target-cpu=native"/' \
    -e 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/' \
    -e 's/xz/xz -T 0/' \
    -e 's/zstd/zstd -T0/' \
    /etc/makepkg.conf
