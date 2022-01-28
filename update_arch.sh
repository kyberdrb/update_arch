#!/bin/sh

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
  mkdir "${LOG_DIR}" 2>/dev/null
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
  clear -x

  # TODO for debugging purposes; reason: testing pacman's parallel downloading + visibility of the 'pacman' and 'pikaur' install scripts
  echo
  echo "Pacman's parallel downloads show progress bars, as a sign of feedback, but only when run outside of the script manually"
  echo "Press 'Ctrl + Shift + V' to paste system upgrade commands"
  echo
  printf "%s" "sudo pacman --sync --refresh --refresh --sysupgrade --needed --verbose --noconfirm --config "${SCRIPT_DIR}/config/pacman.conf" && pikaur --sync --refresh --refresh --sysupgrade --needed --verbose --noedit --nodiff --noconfirm --config "${SCRIPT_DIR}/config/pacman.conf" --pikaur-config "${SCRIPT_DIR}/config/pikaur.conf" --overwrite /usr/lib/p11-kit-trust.so --overwrite /usr/bin/fwupdate --overwrite /usr/share/man/man1/fwupdate.1.gz" | xclip -selection clipboard

  echo
  exit

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

  echo "tail -n $update_log_lines ""$PACMAN_LOG_FILE"" | less"

  echo "But if something went wrong"
  echo "check the configurations"
  echo "and the pacman log with the command"
  echo
  echo "tail -n $update_log_lines ""$PACMAN_LOG_FILE"" | less"
  echo
  echo "or check the full output of the script with"
  echo
  echo "less ${LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}.log" | xclip -selection clipboard
  echo
  echo "which has been btw already copied into your clipboard."
  echo "Press 'Ctrl + Shift + V' to paste the command."
  echo
  echo "================================================================================"
  echo

  script_name
  script_name="$(basename "$0")"

  ln -sf "${SCRIPT_DIR}/$script_name" "$HOME/$script_name"
  ln -sf "${SCRIPT_DIR}/update_all_installed_ignored_packages.sh" "$HOME/update_all_installed_ignored_packages.sh"
  ln -sf "${SCRIPT_DIR}/utils/remount_boot_part_as_writable.sh" "$HOME/remount_boot_part_as_writable.sh"

  echo "A link to the update scripts and to remounting script"
  echo "have been made in your home directory"
  echo "for more convenient launching at"
  echo
  echo "~/${script_name}"
  echo "~/update_all_installed_ignored_packages.sh"
  echo
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

