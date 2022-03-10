#!/usr/bin/bash

set -eux

echo "Checking UEFI boot mode"
test -d /sys/firmware/efi/efivars

echo "Updating system clock"
timedatectl set-timezone Europe/Paris
timedatectl set-ntp true

echo "Preparing disk"
echo -e ',512M,U\n,,L' | sfdisk --label gpt /dev/vda
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
# Only needed for x86_64, because aarch64 mirrors do GeoIP based balancing. The
# reflector package doesn't exist for aarch64.
if [ "$(uname -m)" == x86_64 ]; then
	systemctl disable --now reflector
	reflector --country France,Germany \
	          --latest 5 \
	          --protocol https \
	          --sort rate \
	          --save /etc/pacman.d/mirrorlist
fi

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
