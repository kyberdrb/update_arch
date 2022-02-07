#!/bin/sh

set -x

main() {
  REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")"
  CUSTOM_LOG_DIR="${REPO_DIR}/logs"
  mkdir --parents "${CUSTOM_LOG_DIR}"

  "${REPO_DIR}/pre-transaction-launcher.sh"

  BACKUP_TIME_AND_DATE=$(cat "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log")

  sudo exo-open --launch TerminalEmulator --geometry=240x24 --display :0.0 --show-menubar --show-borders --hide-toolbar --hold --command="pacman --sync --refresh --refresh --sysupgrade --needed --verbose --noconfirm --config "${REPO_DIR}/config/pacman.conf""

  sudo exo-open --launch TerminalEmulator --geometry=240x24 --display :0.0 --show-menubar --show-borders --hide-toolbar --hold --command="pikaur --sync --refresh --refresh --sysupgrade --needed --verbose --noedit --nodiff --noconfirm --config "${REPO_DIR}/config/pacman.conf" --pikaur-config "${REPO_DIR}/config/pikaur.conf" --overwrite /usr/lib/p11-kit-trust.so --overwrite /usr/bin/fwupdate --overwrite /usr/share/man/man1/fwupdate.1.gz"
  
  "${REPO_DIR}/post-transaction-launcher.sh" 2>&1 | tee "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-$(date "+%Y_%m_%d-%H_%M_%S")-post-transaction.log"
}

main

