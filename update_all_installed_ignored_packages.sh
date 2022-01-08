#!/bin/sh

SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"
"${SCRIPT_DIR}/utils/remount_boot_part_as_writable.sh"

locally_installed_ignored_packages_for_upgrade="$(pacman --query --quiet $(cat /etc/pacman.conf | grep IgnorePkg | cut -d '=' -f2) 2>/dev/null | tr '\n' ' ')"

sudo pacman -Syy --needed --noconfirm $locally_installed_ignored_packages_for_upgrade
pikaur -Syy --needed --noconfirm $locally_installed_ignored_packages_for_upgrade

