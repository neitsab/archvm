# Arch VM

This set of scripts perform a minimal Arch Linux install in a QEMU VM configured to use UEFI firmware and `virtio-blk` driver (`/dev/vda` storage device). It embodies the results of my numerous experiments with arch installs and uses my (hardcoded for now) preferences for that task, meaning:

* UEFI + GPT partitioning
* 512 MiB FAT32 ESP partition mounted on `/boot` + XFS root partition using the remaining space
* [Unified kernel image](https://wiki.archlinux.org/title/Unified_kernel_image) booting configured with `efibootmgr` (no boot manager), enabling...
* root param-less, fstab-less config by relying on the [DIscoverable Partitions Spec](https://systemd.io/DISCOVERABLE_PARTITIONS/) and `systemd-gpt-auto-generator` (`/boot` is automounted after boot upon first access)
* full-stack systemd: initramfs, network (DHCP), resolver, timesync
* basic system config done pre-chroot with [systemd-firstboot](https://man.archlinux.org/man/core/systemd/systemd-firstboot.1.en)
* locked root account with `archvm` user configured for `sudo`
* ZSH shell with GRML config, shell completions and syntax highlighting (the same setup as on the Arch install media)
* [micro](https://micro-editor.github.io/) text editor
* French locale, keymap & timezone
* hardcoded pacman mirrorlist with trusted servers from France & Germany

The aim is to provide a minimal, solid foundation which may serve as the basis for any kind of Arch VM.

## Usage

Once booted 1) in the Arch Live environment 2) in a QEMU *UEFI* VM 3) using the `virtio-blk` storage driver (and therefore with a `/dev/vda` as storage device), follow the installation guide from [this point](https://wiki.archlinux.org/title/Installation_guide#Set_the_console_keyboard_layout) up until you have Internet access, then download the script:

    curl -OL https://github.com/neitsab/archvm/raw/master/install.sh

Review and edit it as desired, then execute it:

    bash install.sh

If you are ok with what the script does, you can combine both steps in one command:

    curl -sL https://github.com/neitsab/archvm/raw/master/install.sh | bash

> **/!\ Warning:** This will irremediably destroy anything that was on `/dev/vda`.

## Perspectives

* verify whether the two disjointed scripts can be merged into one single file
* make the script more modular to support a wider range of use cases, maybe making use of the excellent [Setting Variables and Collecting User Input](https://disconnected.systems/blog/archlinux-installer/#setting-variables-and-collecting-user-input).

## Credits

Credits go to the [original author](https://github.com/peterstace/archvm) from which I forked this repo. It was the first time I had seen an Arch install script that felt manageable and close enough to what I personally wanted. This led me to finally push forward and get one out myself. [*Nanos gigantum umeris insidentes*](https://en.wikipedia.org/wiki/Standing_on_the_shoulders_of_giants) indeed!
