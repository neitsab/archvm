# Arch VM

This set of scripts perform a minimal Arch Linux install in a QEMU VM configured to use UEFI firmware and `virtio-blk` driver (`/dev/vda` storage device). It embodies the results of my numerous experiments with arch installs and uses my (hardcoded for now) preferences for that task, meaning:

* UEFI + GPT partitioning
* 512 MiB FAT32 ESP partition mounted on `/boot` + XFS root partition using the remaining space
* [Unified kernel image](https://wiki.archlinux.org/title/Unified_kernel_image) booting configured with `efibootmgr` (no boot manager), enabling...
* kernel cmdline-less, fstab-less config by relying on the [DIscoverable Partitions Spec](https://systemd.io/DISCOVERABLE_PARTITIONS/) and `systemd-gpt-auto-generator`: `/boot` is automounted after bootup when accessed
* thereby full-stack systemd: initramfs, network (DHCP), resolver, timesync
* locked root account with `archvm` user gaining elevated privilege via `sudo`
* ZSH shell with GRML config, shell completions and syntax highlighting (the same setup as on the Arch install media)
* [micro](https://micro-editor.github.io/) text editor
* French locale, keymap & timezone
* 5 fastest HTTPS mirrors among the latest synchronized from France & Germany

The aim is to provide a minimal, solid foundation which may serve as the basis for any kind of Arch VM.
