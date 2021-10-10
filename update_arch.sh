#!/bin/bash

prepare_environment() {
  sudo echo

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

  SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"
  PACMAN_LOG_FILE="$(extract_path_from_pacman_workspace 'Log File')"
  LOG_LINE_NUMBER_BEGIN=$(wc -l "$PACMAN_LOG_FILE" | cut -d' ' -f1)

  LOG_DIR="${SCRIPT_DIR}/logs"
  mkdir "${LOG_DIR}"
  echo "Log dir for update script: ${LOG_DIR}"

  BACKUP_TIME_AND_DATE=$(date "+%Y_%m_%d-%H_%M_%S")
}

# TODO extract duplicate function from all scripts into a separate script to be imported in all files
extract_path_from_pacman_workspace() {
  local pacman_workspace
  pacman_workspace="$(pacman --verbose 2>/dev/null)"
  
  local searched_text="$1"
  
  local extracted_text
  extracted_text=$(echo -e "$pacman_workspace" | grep "$searched_text" | tr -d ' ' | cut -d':' -f2)
  echo "$extracted_text"
}

launch_update_script() {
  "$SCRIPT_DIR/update_arch-worker.sh" 2>&1 | tee "${LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}.log"
}

finalize() {
  clear -x

  echo "=========================================="
  echo "Editing Chromium shortcut in order"
  echo "to disable 'gnome-keyring' password prompt"
  echo "------------------------------------------"

  "${SCRIPT_DIR}/utils/chromium_disable_gnome-keyring_password_prompt.sh"

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

  local log_line_number_end
  log_line_number_end=$(wc -l "$PACMAN_LOG_FILE" | cut -d' ' -f1)
  
  local update_log_lines=$((log_line_number_end - LOG_LINE_NUMBER_BEGIN))

  echo "tail -n $update_log_lines ""$PACMAN_LOG_FILE"" | less" | xclip -selection clipboard

  echo "But if something went wrong"
  echo "check the configurations"
  echo "and the pacman log with the command"
  echo
  echo "  tail -n $update_log_lines ""$PACMAN_LOG_FILE"" | less"
  echo
  echo "which has been btw already copied into your clipboard."
  echo "Press 'Ctrl + Shift + V' to paste the command."
  echo
  echo "or check the full output of the script with"
  echo
  echo "  less ${LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}.log"
  echo
  echo "================================================================================"
  echo

  local script_name
  script_name="$(basename "$0")"

  ln -sf "${SCRIPT_DIR}/$script_name" "$HOME/$script_name"
  ln -sf "${SCRIPT_DIR}/utils/remount_boot_part_as_writable.sh" "$HOME/remount_boot_part_as_writable.sh"

  echo "A link to the update script and to remounting script"
  echo "have been made in your home directory"
  echo "for more convenient launching at"
  echo "  ~/${script_name}"
  echo "and"
  echo "  ~/remount_boot_part_as_writable.sh"
  echo
}

main() {
  prepare_environment
  launch_update_script
  finalize
}

main

