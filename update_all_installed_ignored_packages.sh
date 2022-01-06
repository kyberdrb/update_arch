#!/bin/sh

locally_installed_ignored_packages_for_upgrade="$(pacman --query --quiet $(cat /etc/pacman.conf | grep IgnorePkg | cut -d '=' -f2) 2>/dev/null | tr '\n' ' ')"

sudo powerpill -Syy --noconfirm $locally_installed_ignored_packages_for_upgrade
pikaur -Syy --noconfirm $locally_installed_ignored_packages_for_upgrade

