#!/bin/bash

prepare_environment() {
  sudo echo

  SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"
  PACMAN_DEFAULT_CONFIG_FILE="$(extract_path_from_pacman_workspace 'Conf File')"
  PACMAN_DB_PATH="$(extract_path_from_pacman_workspace 'DB Path')"
  PACMAN_GPG_DIR="$(extract_path_from_pacman_workspace 'GPG Dir')"
  PACMAN_LOG_FILE="$(extract_path_from_pacman_workspace 'Log File')"

  LOG_LINE_NUMBER_BEGIN=$(wc -l "$PACMAN_LOG_FILE" | cut -d' ' -f1)

  local custom_config_dir
  custom_config_dir="${SCRIPT_DIR}/config"
  PACMAN_CUSTOM_CONFIG="${custom_config_dir}/pacman.conf"
  PIKAUR_CUSTOM_CONFIG="${custom_config_dir}/pikaur.conf"
  POWERPILL_CUSTOM_CONFIG="${custom_config_dir}/powerpill.json"
  GPG_CUSTOM_CONFIG="${custom_config_dir}/gpg.conf"

  # TODO extract echo statements with decorations into function to remove duplicate code
  echo "================================================================================"
  echo
  echo "Script directory: $SCRIPT_DIR"
  echo "Pacman default config file: $PACMAN_DEFAULT_CONFIG_FILE"
  echo "Pacman database path: $PACMAN_DB_PATH"
  echo "Pacman GPG directory: $PACMAN_GPG_DIR"
  echo "Pacman log file: $PACMAN_LOG_FILE"
  echo
  echo "================================================================================"
  echo
}

extract_path_from_pacman_workspace() {
  local pacman_workspace
  pacman_workspace="$(pacman --verbose 2>/dev/null)"
  
  local searched_text="$1"
  
  local extracted_text
  extracted_text=$(echo -e "$pacman_workspace" | grep "$searched_text" | tr -d ' ' | cut -d':' -f2)
  echo "$extracted_text"
}

set_up_pacman_configuration() {
  echo "==========================="
  echo "Set up pacman configuration"
  echo "==========================="
  echo

  echo "==================================="
  echo "Backup current pacman configuration"
  echo "-----------------------------------"
  echo

  BACKUP_TIME_AND_DATE=$(date "+%Y_%m_%d-%H_%M_%S")
  sudo cp --dereference "$PACMAN_DEFAULT_CONFIG_FILE" "${PACMAN_DEFAULT_CONFIG_FILE}-${BACKUP_TIME_AND_DATE}.bak"

  echo "======================================================="
  echo "Link embedded 'pacman' configuration file to the system"
  echo "-------------------------------------------------------"
  echo

  #TODO use the long, keyword options '--' instead of the one-letter ones for better readability for all commands
  sudo ln -sf "$PACMAN_CUSTOM_CONFIG" "$PACMAN_DEFAULT_CONFIG_FILE"
}

set_up_pikaur() {
  echo "============="
  echo "Set up pikaur"
  echo "============="
  echo

  PIKAUR_INSTALLED=$(pacman --query | grep pikaur)
  if [[ -z $PIKAUR_INSTALLED ]]; then 
    rm -rf /tmp/pikaur-git
    mkdir /tmp/pikaur-git
    curl https://aur.archlinux.org/cgit/aur.git/snapshot/pikaur-git.tar.gz --output /tmp/pikaur-git.tar.gz
    tar -xvzf /tmp/pikaur-git.tar.gz --directory /tmp/pikaur-git
    cd /tmp/pikaur-git/pikaur-git || exit
    makepkg --ignorearch --clean --syncdeps --noconfirm
    PIKAUR_PACKAGE_NAME=$(ls -- *.tar*)

    sudo pacman \
        --verbose \
        --upgrade \
        --noconfirm \
        --config "$PACMAN_CUSTOM_CONFIG" \
      "$PIKAUR_PACKAGE_NAME"
    
    rm -rf /tmp/pikaur-git
  fi

  echo "================================================="
  echo "'pikaur' package installed"
  echo 'Arch User Repository (AUR) Package Helper present'
  echo "-------------------------------------------------"
  echo 

  echo "======================================================="
  echo "Link embedded 'pikaur' configuration file to the system"
  echo "-------------------------------------------------------"
  echo

  ln -sf "$PIKAUR_CUSTOM_CONFIG" "${HOME}/.config/pikaur.conf"
}

update_repo_of_this_script() {
  echo "========================================"
  echo "Download latest version of update script"
  echo "========================================"
  echo

  local git_pull_status
  git_pull_status=$(git -C "$SCRIPT_DIR" pull)

  echo "$git_pull_status" | grep --invert-match "Already up to date."

  test $? -eq 0

  local is_local_repo_outdated="$?"
  if [[ is_local_repo_outdated -eq 0 ]]; then
    echo "Repository updated."
    echo "Please, run the script again."
    exit 1
  fi

  echo "======================================="
  echo "Script is already in the latest version"
  echo "---------------------------------------"
  echo
}

update_pacman_mirror_servers() {
  echo "====================================="
  echo "Download fresh list of mirror servers"
  echo "====================================="
  echo

  "${SCRIPT_DIR}"/utils/update_pacman_mirror_servers.sh
}

update_arch_linux_keyring() {
  echo "=============================="
  echo "Update Arch Linux keyring"
  echo " to avoid PGP signature errors"
  echo "=============================="

  echo
  echo "======================"
  echo "Cleanup GPG keys first"
  echo " see https://bbs.archlinux.org/viewtopic.php?pid=1837082#p1837082"
  echo "----------------------"
  echo

  sudo rm -R "$PACMAN_GPG_DIR"
  sudo rm -R /root/.gnupg/
  rm -rf ~/.gnupg/

  echo "========================="
  echo "Initialize pacman keyring"
  echo "-------------------------"
  echo

  sudo pacman-key --init

  echo
  echo "===================================================="
  echo "Link embedded 'gpg' configuration file to the system"
  echo "----------------------------------------------------"
  echo

  sudo ln -sf "$GPG_CUSTOM_CONFIG" "${PACMAN_GPG_DIR}gpg.conf"

  echo "====================================================="
  echo "Add GPG keys for custom repositories and AUR packages"
  echo "-----------------------------------------------------"
  echo

  sudo pacman-key --populate archlinux
  sudo gpg --refresh-keys

  #TODO extract repeating GPG commands into a separate function
  # that will automatically switch between pacman-key and gpg commands
  # by to an argument
  echo
  echo "================================"
  echo "Add GPG key for seblu repository"
  echo '(unofficial repo)'
  echo "--------------------------------"
  echo

  sudo pacman-key --recv-keys 76F3EB6DA1C5F938AD642DC438DCEEBE387A1EEE
  sudo pacman-key --lsign-key 76F3EB6DA1C5F938AD642DC438DCEEBE387A1EEE

  echo
  echo "====================================="
  echo "Add GPG key for 'liquorix' repository"
  echo '(unofficial repo)'
  echo "-------------------------------------"
  echo

  sudo pacman-key --recv-keys 9AE4078033F8024D
  sudo pacman-key --lsign-key 9AE4078033F8024D

  echo
  echo "========================================="
  echo "Add GPG key for 'ck' repository - graysky"
  echo '(unofficial repo)'
  echo "-----------------------------------------"
  echo
   
  sudo pacman-key --recv-keys 5EE46C4C --keyserver hkp://pool.sks-keyservers.net
  sudo pacman-key --lsign-key 5EE46C4C

  echo
  echo "========================================"
  echo "Add GPG key for 'post-factum' repository"
  echo '(unofficial repo)'
  echo "----------------------------------------"
  echo

  sudo pacman-key --keyserver hkp://pool.sks-keyservers.net --recv-keys 95C357D2AF5DA89D
  sudo pacman-key --lsign-key 95C357D2AF5DA89D
 
  echo
  echo "======================================"
  echo "Add GPG key for 'chaotic' repository:"
  echo " Pedro Henrique Lara Campos - pedrohlc"
  echo '(unofficial repo)'
  echo "--------------------------------------"
  echo

  sudo pacman-key --keyserver hkp://pool.sks-keyservers.net --recv-keys 3056513887B78AEB
  sudo pacman-key --lsign-key 3056513887B78AEB

  echo
  echo "================================================="
  echo "Add GPG key for Pedram Pourang - tsujan"
  echo "Required when building 'compton-conf' AUR package"
  echo '  see (https://aur.archlinux.org/packages/compton-conf/#pinned-742136)'
  echo '(AUR repo)'
  echo "-------------------------------------------------"
  echo

  gpg --recv-keys BE793007AD22DF7E
  gpg --lsign-key BE793007AD22DF7E

  echo
  echo "==========================================================="
  echo "Uprade keyrings and additional mirrorlists for repositories"
  echo "-----------------------------------------------------------"
  echo

  #TODO extract repeating pikaur, and maybe pacman and powerpill statements into a separate function with variable number of arguments
  pikaur \
    --sync \
    --refresh --refresh \
    --verbose \
    --config "$PACMAN_CUSTOM_CONFIG" \
    --pikaur-config "$PIKAUR_CUSTOM_CONFIG"

  pikaur \
      --sync \
      --refresh \
      --verbose \
      --noconfirm \
      --config "$PACMAN_CUSTOM_CONFIG" \
      --pikaur-config "$PIKAUR_CUSTOM_CONFIG" \
    archlinux-keyring

  echo 
  echo "====================================================="
  echo "'chaotic-mirrorlist' adds separate mirrorlist file in"
  echo "  /etc/pacman.d/chaotic-mirrorlist"
  echo "-----------------------------------------------------"
  echo

  pikaur \
      --sync \
      --refresh \
      --verbose \
      --noconfirm \
      --config "$PACMAN_CUSTOM_CONFIG" \
      --pikaur-config "$PIKAUR_CUSTOM_CONFIG" \
    chaotic-mirrorlist

  echo
  echo "====================================================="
  echo "'chaotic-keyring' add GPG keys for 'chaotic-aur' repo"
  echo "-----------------------------------------------------"
  echo "For chaotic-aur repo setup, see page"
  echo "  https://lonewolf.pedrohlc.com/chaotic-aur/"
  echo "-----------------------------------------------------"
  echo

  pikaur \
      --sync \
      --refresh \
      --verbose \
      --noconfirm \
      --config "$PACMAN_CUSTOM_CONFIG" \
      --pikaur-config "$PIKAUR_CUSTOM_CONFIG" \
    chaotic-keyring 
}

remount_boot_partition_as_writable() {
  echo
  echo "============================================"
  echo "Remounting boot partition as writable"
  echo " in order to make he upgrade of kernel"
  echo " and other kernel dependend modules possible"
  echo "============================================"
  echo

  "${SCRIPT_DIR}"/utils/remount_boot_part_as_writable.sh
}

install_script_dependencies() {
  echo
  echo "========================================"
  echo "Installing/Upgrading script dependencies"
  echo "========================================"
  echo

  pikaur \
      --sync \
      --refresh \
      --needed \
      --noconfirm \
      --config "$PACMAN_CUSTOM_CONFIG" \
      --pikaur-config "$PIKAUR_CUSTOM_CONFIG" \
    pikaur powerpill reflector rsync shellcheck

  echo
  echo "=========================================================="
  echo "Link embedded 'powerpill' configuration file to the system"
  echo "----------------------------------------------------------"
  echo

  sudo ln -sf "$POWERPILL_CUSTOM_CONFIG" /etc/powerpill/powerpill.json
}

check_script_syntax() {
  echo "================================="
  echo "Check script for syntactic errors"
  echo "================================="
  echo 

  shellcheck "$0"
}

upgrade_packages() {
  echo "==============================="
  echo "Updating and upgrading packages"
  echo "==============================="
  echo 

  echo "========================"
  echo "Clear 'pacman' databases"
  echo "------------------------"
  echo

  sudo rm -rf "$PACMAN_DB_PATH"/sync/*

  echo "==================================="
  echo "Checking for updates..."
  echo "-----------------------------------"
  echo

  pikaur_output=$(echo -ne 'n\n' | pikaur \
    --sync \
    --refresh \
    --refresh \
    --sysupgrade \
    --sysupgrade \
    --config "$PACMAN_CUSTOM_CONFIG" \
    --pikaur-config "$PIKAUR_CUSTOM_CONFIG" 2>&1)

  echo -e "$pikaur_output" | grep "there is nothing to do"
  test $? -ne 0
  local are_updated_packages_avaliable="$?"

  if [[ are_updated_packages_avaliable -eq 0 ]]; then
    echo -e "$pikaur_output"
    echo

    echo
    echo "=========================================================="
    echo "Pacman configuration file"
    echo "had been patched for 'powerpill' to resolve error messages"
    echo "according to"
    echo " https://wiki.archlinux.org/index.php/Powerpill#Troubleshooting"
    echo "and"
    echo " https://bbs.archlinux.org/viewtopic.php?pid=1254940#p1254940"
    echo "---------------------------------------------------------------"

    echo
    echo "TODO replace 'powerpill' with 'pacman'"
    echo "when 'pacman 6.0' or higher will be officialy released"

    sudo powerpill \
        --sync \
        --refresh --refresh \
        --sysupgrade --sysupgrade \
        --needed \
        --verbose \
        --noconfirm \
        --config "$PACMAN_CUSTOM_CONFIG" \
        --powerpill-config "$POWERPILL_CUSTOM_CONFIG"

    echo
    echo "===================================================="
    echo "Updating and upgrading packages AUR packages"
    echo "and official packages that haven't yet been updated"
    echo "to the latest version or haven't been updated at all"
    echo "----------------------------------------------------"
    echo 

    pikaur \
        --sync \
        --refresh --refresh \
        --sysupgrade --sysupgrade \
        --verbose \
        --noedit \
        --nodiff \
        --noconfirm \
        --config "$PACMAN_CUSTOM_CONFIG" \
        --pikaur-config "$PIKAUR_CUSTOM_CONFIG" \
        --overwrite /usr/lib/p11-kit-trust.so \
        --overwrite /usr/bin/fwupdate \
        --overwrite /usr/share/man/man1/fwupdate.1.gz
  fi
}

clean_up() {
  echo
  echo "=================="
  echo "Removing leftovers"
  echo "=================="

  rm -rf ~/.libvirt
  sudo powerpill --powerpill-clean
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
  echo "================================================================================"
  echo

  local full_script_path
  full_script_path="$(readlink --canonicalize "$0")"
  
  local script_name
  script_name="$(basename "$0")"
  
  ln -sf "$full_script_path" "$HOME/$script_name"
  ln -sf "${SCRIPT_DIR}/utils/remount_boot_part_as_writable.sh" "$HOME/remount_boot_part_as_writable.sh"

  echo "A link to the update script and to remounting script"
  echo "have been made in your home directory"
  echo "for more convenient launching at"
  echo "  $(ls "$HOME"/"$script_name")"
  echo "and"
  echo "  $(ls "$HOME"/remount_boot_part_as_writable.sh)"
  echo
}

main() {
  prepare_environment
  set_up_pacman_configuration 
  set_up_pikaur
  update_repo_of_this_script
  update_pacman_mirror_servers
  update_arch_linux_keyring
  remount_boot_partition_as_writable
  install_script_dependencies
  check_script_syntax
  upgrade_packages
  clean_up
  finalize
}

main

