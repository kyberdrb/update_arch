# Arch Linux Updater

**Always do a backup or clone before upgrading the system. When something breaks or fails, you will have something to rely on.**

Update script for fully automatizing the updating of an Arch Linux.

But when GPG keys change, or something goes terribly wrong, manual intervention is needed.

## Usage

`./update_arch.sh`

## Preventing a kernel panic

Kernel panic is a situation when the system doesn't boot after some modification, i.e. upgrading the kernel, installing a conflicting module etc.

To prevent this, some packages are present in the `pacman.conf` in the `IgnorePkg` attribute to ensure more stable and robust system between upgrades.

You can even make freeze multiple packages and kernel flavours tha you wish to keep in order to prevent such unpleasant surprises

    IgnorePkg = linux-lqx linux-lqx-headers linux-clear-bin linux-clear-headers-bin linux-tkg-muqss-skylake linux-tkg-muqss-skylake-headers linux-ck-skylake linux-ck-skylake-headers linux-pf-skylake linux-pf-headers-skylake linux linux-headers

### When a kernel panic occurs...

the system freezes at boot. At least in my case. Only hard shutdown, long pressing the power button, shuts off the system.

The solution is to downgrade the kernel version to the latest working version. As the main system is unbootable, we need to use alternative methods. You can always do a full restore from backed up/cloned drive. You can also use Arch Linux installation USB to downgrade the kernel to the last working version or swap current kernel for some other one that previously worked, unless you wipe the locally stored packages in pacman cache with `sudo pacman -Scc`. So the cached packages may save you a lot of time when something breaks.

1. Boot from the Arch Linux installation USB.

1. List all disks and partitions

        lsblk

        NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
        sda      8:0    0 238.5G  0 disk 
        ├─sda1   8:1    0   600M  0 part /boot
        └─sda2   8:2    0   220G  0 part /

    In my case, `sda2` is the `root` partition `/`, `sda1` is the `boot` partition - bootloader mounted to directory `/boot/`.

1. Mount the root partition first, then the boot partition

        mount /dev/sda2 /mnt
        mount /dev/sda1 /mnt/boot

1. Switch to the mounted Arch Linux installation

        arch-chroot /mnt

1. (A) If you want to downgrade existing kernel, first list all available linux kernels, and then install the desired version

        ls -l /var/cache/pacman/pkg/ | grep ^linux*

    Choose the package with the kernel version that worked previously from the list.

    Install the package with command

        pacman -U linux-KERNEL_INFO.pkg.tar.zst

    Reboot

        exit
        reboot

    The system will boot and be stable and usable again.

    Now you can skip the rest of the guide when the system is functional.

1. (B) If you want to try out differetn kernels, first list all available kernel presets

        ls -1 /etc/mkinitcpio.d/

    Choose the desired kernel.

    Replace existing preset in the bootloader configuration file for the chosen one without the `.preset` suffix by editing the file

        sudo nano /boot/loader/entries/arch.conf
        
    or

        sudo vim /boot/loader/entries/arch.conf
    
    Replace lines

        ...
        linux /vmlinuz-CHOSEN_KERNEL_PRESET_NAME
        initrd /initramfs-CHOSEN_KERNEL_PRESET_NAME.img
        ...

    Save file, exit the editor, exit the chroot environment and reboot the machine

        exit
        reboot

    Sometimes the system boots, sometimes it doesn't. Be prepared to boot from the Arch Linux installation USB drive multiple times and try out different kernel versions and types to attain a bootable, usable and stable system again.

- https://archlinux.org/pacman/pacman.conf.5.html#_options
- https://wiki.archlinux.org/index.php/System_maintenance
- https://github.com/kyberdrb/arch_linux_installation_guide/blob/master/README.md
- https://www.unixmen.com/solve-arch-linux-kernel-panic/

Sources:

Kernel parameters: https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/kernel-parameters.txt

Shell script syntax checker: https://www.shellcheck.net/

https://www.archlinux.org/mirrors/status/

https://linuxize.com/post/how-to-read-a-file-line-by-line-in-bash/

https://stackoverflow.com/questions/14093452/grep-only-the-first-match-and-stop/14093511#14093511

https://stackoverflow.com/questions/1403087/how-can-i-convert-an-html-table-to-csv/10189130#10189130

https://stackoverflow.com/questions/1403087/how-can-i-convert-an-html-table-to-csv/10189130#10189130

https://kifarunix.com/delete-lines-matching-a-specific-pattern-in-a-file-using-sed/

https://www.2daygeek.com/remove-delete-empty-lines-in-a-file-in-linux/

https://stackoverflow.com/questions/1251999/how-can-i-replace-a-newline-n-using-sed/1252010#1252010

https://phoenixnap.com/kb/grep-multiple-strings

https://wiki.archlinux.org/index.php/Powerpill#Troubleshooting

https://bbs.archlinux.org/viewtopic.php?pid=1254940#p1254940

https://xyne.archlinux.ca/projects/powerpill/

[pikaur - configuration file from custom path](https://github.com/actionless/pikaur/blob/5f2d8a7535e429c2387de23d65e6c47b1f463e56/pikaur/config.py#L48)

https://wiki.archlinux.org/index.php/System_maintenance

---

https://wiki.archlinux.org/index.php/Unofficial_user_repositories/Repo-ck#Add_Repo

https://lonewolf.pedrohlc.com/chaotic-aur/

