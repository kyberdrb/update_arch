#!/bin/sh

set -x

REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")/.."

"${REPO_DIR}/utils/remount_boot_part_as_writable.sh"

CUSTOM_LOG_DIR="${REPO_DIR}/logs"
BACKUP_TIME_AND_DATE=$(date "+%Y_%m_%d-%H_%M_%S")

locally_installed_ignored_packages_for_upgrade="$(pacman --query --quiet $(cat /etc/pacman.conf | grep IgnorePkg | cut -d '=' -f2) 2>/dev/null | tr '\n' ' ')"

sudo exo-open --launch TerminalEmulator --geometry=240x24 --display :0.0 --show-menubar --show-borders --hide-toolbar --hold --command="sudo pacman --sync --refresh --refresh --needed --verbose --noconfirm --config "${REPO_DIR}/config/pacman.conf" ${locally_installed_ignored_packages_for_upgrade} 2>&1 | tee "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-ignored_packages_upgrade-pacman.log" && pikaur --sync --refresh --refresh --needed --verbose --noedit --nodiff --noconfirm --config ${locally_installed_ignored_packages_for_upgrade} 2>&1 | tee "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-ignored_packages_upgrade-pikaur.log""

