#!/bin/sh

set -x

REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")"

"${REPO_DIR}/utils/remount_boot_part_as_writable.sh"

CUSTOM_LOG_DIR="${REPO_DIR}/logs"
BACKUP_TIME_AND_DATE=$(date "+%Y_%m_%d-%H_%M_%S")

locally_installed_ignored_packages_for_upgrade="$(pacman --query --quiet $(cat /etc/pacman.conf | grep IgnorePkg | cut -d '=' -f2) 2>/dev/null | tr '\n' ' ')"

if [ -z "${DISPLAY}" ]
then
  pacman --sync --refresh --refresh --needed --verbose --noconfirm ${locally_installed_ignored_packages_for_upgrade}
  pikaur --sync --refresh --refresh --needed --verbose --noedit --nodiff --noconfirm ${locally_installed_ignored_packages_for_upgrade}
else
  terminal_emulator="$(pacman -Qq | grep terminal)"

  sudo "${terminal_emulator}" --geometry=189x24 --command="pacman --sync --refresh --refresh --needed --verbose --noconfirm ${locally_installed_ignored_packages_for_upgrade}" 2>&1

  sudo "${terminal_emulator}" --geometry=189x24 --command="pikaur --sync --refresh --refresh --needed --verbose --noedit --nodiff --noconfirm ${locally_installed_ignored_packages_for_upgrade}" 2>&1
fi

