#!/bin/sh

set -x

prepare_environment() {
  sudo printf "\r"

  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo
  echo "MAKE SURE YOU DO A BACKUP/CLONE BEFORE SYSTEM UPGRADE"
  echo "      IN CASE SOMETHING GOES WRONG OR BREAKS"
  echo
  echo "         ALWAYS HAVE A CLONEZILLA USB"
  echo "        AND ARCH LINUX INSTALLATION USB"
  echo "                 TO BOOT FROM"
  echo "       TO RECOVER FROM CRITICAL FAILURES"
  echo "         e.g. not bootable system etc."
  echo
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo

  sleep 10

  REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")"

  CUSTOM_LOG_DIR="${REPO_DIR}/logs"
  mkdir --parents "${CUSTOM_LOG_DIR}" 2>/dev/null

  PACMAN_LOG_FILE="$(pacman --verbose | grep 'Log File' | tr -d ' ' | cut -d':' -f2)"

  # share the same initiation time for all scripts and logs
  #  in order to filter them easier with shell commands later
  date "+%Y_%m_%d-%H_%M_%S" > "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log"
  BACKUP_TIME_AND_DATE=$(cat "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log")
}

launch_script() {
  "${REPO_DIR}/utils/pre-transaction.sh" 2>&1 | tee "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-$(date "+%Y_%m_%d-%H_%M_%S")-pre-transaction.log"
}

finalize() {
  wc -l "${PACMAN_LOG_FILE}" | cut -d' ' -f1 > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-pacman_log-starting_line_for_this_update_session.log"

  echo "================================================================================"
  echo

  script_name="$(basename "$0")"

  ln -sf "${REPO_DIR}/$script_name" "$HOME/$script_name"
  ln -sf "${REPO_DIR}/update_all_installed_ignored_packages.sh" "$HOME/update_all_installed_ignored_packages.sh"
  ln -sf "${REPO_DIR}/utils/remount_boot_part_as_writable.sh" "$HOME/remount_boot_part_as_writable.sh"

  echo "A link to this script had been made in your home directory"
  echo "for more convenient launching at"
  echo
  echo "${HOME}/${script_name}"
  echo "${HOME}/update_all_installed_ignored_packages.sh"
  echo
  echo "and"
  echo "${HOME}/remount_boot_part_as_writable.sh"
  echo
}

main() {
  prepare_environment
  launch_script
  finalize
}

main
