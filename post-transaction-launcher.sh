#!/bin/sh

set -x

prepare_environment() {
  REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")"
  PACMAN_LOG_FILE="$(pacman --verbose | grep 'Log File' | tr -d ' ' | cut -d':' -f2)"

  CUSTOM_LOG_DIR="${REPO_DIR}/logs"
  BACKUP_TIME_AND_DATE=$(cat "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log")
}

launch_script() {
  "${REPO_DIR}/utils/post-transaction.sh"
}

finalize() {
  echo "================================================================================"
  echo "Please, reboot to apply updates"
  echo "for kernel, firmware, graphics drivers"
  echo "or other drivers and services"
  echo "requiring service restart or system reboot."
  echo
  echo "After reboot test:"
  echo "  - 'journalctl --boot --reverse' for any error messages"
  echo "  - virtual machines"
  echo "  - USB functionality"
  echo "================================================================================"

  log_line_number_begin="$(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-pacman_log-starting_line_for_this_update_session.log")"

  log_line_number_end="$(wc -l "$PACMAN_LOG_FILE" | cut -d' ' -f1)"
  update_log_lines=$(( log_line_number_end - log_line_number_begin ))

  echo "But if something went wrong"
  echo "check the configurations"
  echo "and the pacman log with the command"
  echo
  echo "tail -n $update_log_lines ${PACMAN_LOG_FILE} | less"
  echo

  echo "or check the full output of the script with"
  echo

  log_file_all_in_one="${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-$(date "+%Y_%m_%d-%H_%M_%S")-all_in_one.log"
  find "${CUSTOM_LOG_DIR}/" -name "update_arch-${BACKUP_TIME_AND_DATE}*" | sort | xargs -I % cat "%" >> "${log_file_all_in_one}" 2>/dev/null

  echo "less ${log_file_all_in_one}" | xclip -selection clipboard
  echo
  echo "which has been btw already copied into your clipboard."
  echo "Press 'Ctrl + Shift + V' to paste the command."
  echo
  echo "================================================================================"
  echo

  script_name="$(basename "$0")"

  echo "=========================================="

  ln -sf "${REPO_DIR}/update_arch.sh" "$HOME/update_arch.sh"
  ln -sf "${REPO_DIR}/$script_name" "$HOME/$script_name"
  ln -sf "${REPO_DIR}/update_all_installed_ignored_packages.sh" "${HOME}/update_all_installed_ignored_packages.sh"
  ln -sf "${REPO_DIR}/utils/remount_boot_part_as_writable.sh" "${HOME}/remount_boot_part_as_writable.sh"

  echo "Links to the update scripts and to remounting script"
  echo "have been made in your home directory"
  echo "for more convenient launching at"
  echo
  echo "${HOME}/update_arch.sh"
  echo "${HOME}/${script_name}"
  echo "${HOME}/update_all_installed_ignored_packages.sh"
  echo "${HOME}/remount_boot_part_as_writable.sh"
  echo "------------------------------------------"
  echo
}

main() {
  prepare_environment
  launch_script
  finalize
}

main

