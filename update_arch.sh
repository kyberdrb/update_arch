#!/bin/bash

prepare_environment() {
  sudo echo

  SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"
  PACMAN_LOG_FILE="$(extract_path_from_pacman_workspace 'Log File')"
  LOG_LINE_NUMBER_BEGIN=$(wc -l "$PACMAN_LOG_FILE" | cut -d' ' -f1)
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
  "$SCRIPT_DIR/update_arch-worker.sh" 2>&1 | tee "$SCRIPT_DIR/update_arch.log"
}

finalize() {
  clear -x

  echo "================================================================================"
  echo "Please, reboot to apply updates"
  echo "for kernel, firmware, graphics drivers"
  echo "or other drivers and services"
  echo "requiring service restart or system reboot."
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
  echo "  less ${SCRIPT_DIR}/update_arch.log"
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
  #launch_update_script
  finalize
}

main

