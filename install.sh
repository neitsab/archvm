#!/usr/bin/bash

set -eux

echo "Checking UEFI boot mode"
test -d /sys/firmware/efi/efivars

echo "Updating system clock"
timedatectl set-timezone Europe/Paris
timedatectl set-ntp true

echo "Preparing disk"
sgdisk -n 1:0:+512MiB -t 1:ef00 -n 2:0:0 -t 2:8304 /dev/vda
mkfs.fat -F 32 /dev/vda1
mkfs.xfs -m bigtime=1,rmapbt=1 /dev/vda2
mount /dev/vda2 /mnt
mkdir /mnt/boot
mount /dev/vda1 /mnt/boot

echo "Fetching chroot script"
# Done as early as possible (after preparing the location to save it to) in
# case internet connectivity is not working.
src="https://raw.githubusercontent.com/neitsab/archvm/master/chroot.sh"
dst="/mnt/chroot.sh"
curl "$src" > "$dst"
chmod +x "$dst"

echo "Selecting mirrors"
# disable reflector service to prevent it from overwriting our manual invocation
systemctl disable --now reflector
reflector --country France,Germany \
          --latest 5 \
          --protocol https \
          --sort rate \
          --save /etc/pacman.d/mirrorlist

echo "Installing base"
pacstrap /mnt \
        base linux efibootmgr\
        micro \
        grml-zsh-config zsh-completions zsh-syntax-highlighting \
        xfsprogs dosfstools \
        sudo

echo "Preparing system with systemd-firstboot"
systemd-firstboot --root=/mnt \
            --locale=fr_FR.UTF-8 \
            --keymap=fr-latin9 \
            --timezone=Europe/Paris \
            --hostname=archvm \
            --root-shell=/usr/bin/zsh \
            --force \

echo "Set up systemd-resolved symlink"
ln -sf /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf

echo "Run chroot script"
arch-chroot /mnt /chroot.sh

echo "Unmounting virtual drive"
umount -R /mnt

echo "Installation complete. You can now:"
echo "  - Shutdown the VM using \`poweroff\`"
echo "  - Remove the installation media"
echo "  - restart the VM"
