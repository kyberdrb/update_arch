#!/bin/sh

set -x

prepare_environment() {
  sudo printf "\r%s"

  REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")/.."

  CUSTOM_CONFIG_DIR="${REPO_DIR}/config"
  PACMAN_CUSTOM_CONFIG="${CUSTOM_CONFIG_DIR}/pacman.conf"
  PIKAUR_CUSTOM_CONFIG="${CUSTOM_CONFIG_DIR}/pikaur.conf"
  GPG_CUSTOM_CONFIG="${custom_config_dir}/gpg.conf"

  PACMAN_DEFAULT_CONFIG_FILE="$(extract_path_from_pacman_workspace 'Conf File')"
  PACMAN_DB_PATH="$(extract_path_from_pacman_workspace 'DB Path')"
  PACMAN_LOG_FILE="$(extract_path_from_pacman_workspace 'Log File')"

  # TODO extract echo statements with decorations into function to remove duplicate code
  echo "================================================================================"
  echo
  echo "Script directory: $REPO_DIR"
  echo "Pacman default config file: $PACMAN_DEFAULT_CONFIG_FILE"
  echo "Pacman database path: $PACMAN_DB_PATH"
  echo "Pacman log file: $PACMAN_LOG_FILE"
  echo
  echo "================================================================================"
  echo
}

extract_path_from_pacman_workspace() {
  searched_text="$1"
  extracted_text="$(pacman --verbose 2--config "${PACMAN_CUSTOM_CONFIG}" 2>/dev/null | grep "${searched_text}" | rev | cut --delimiter=' ' --fields=1 | rev)"
  echo "$extracted_text"
}

set_up_pacman_configuration() {
  echo "==========================="
  echo "Set up pacman configuration"
  echo "==========================="
  echo

  echo "======================================="
  echo "Backup current pacman configuration and" 
  echo "and copy the embedded one"
  echo "---------------------------------------"
  echo

  diff "${PACMAN_CUSTOM_CONFIG}" "/etc/pacman.conf"

  CUSTOM_LOG_DIR="${REPO_DIR}/logs"
  BACKUP_TIME_AND_DATE=$(cat "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log")

  sudo mv "/etc/pacman.conf" "/etc/pacman.conf-${BACKUP_TIME_AND_DATE}.bak"
  sudo cp --force "${PACMAN_CUSTOM_CONFIG}" "/etc/pacman.conf"
}

set_up_pikaur() {
  echo
  echo "============="
  echo "Set up pikaur"
  echo "============="
  echo

  PIKAUR_INSTALLED=$(pacman --query --config "${PACMAN_CUSTOM_CONFIG}" 2>/dev/null | grep pikaur)
  if [ -z "$PIKAUR_INSTALLED" ]
  then 
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
  echo "'pikaur' package helper installed"
  echo "-------------------------------------------------"
  echo 'Arch User Repository (AUR) Package Helper present'
  echo "-------------------------------------------------"
  echo 

  echo "======================================="
  echo "Backup current pikaur configuration and"
  echo "Copy the embedded one"
  echo "---------------------------------------"
  echo

  mv "${HOME}/.config/pikaur.conf" "${HOME}/.config/pikaur.conf-${BACKUP_TIME_AND_DATE}.bak"
  cp --force "$PIKAUR_CUSTOM_CONFIG" "${HOME}/.config/pikaur.conf"
}

update_repo_of_this_script() {
  echo "========================================"
  echo "Download latest version of update script"
  echo "========================================"
  echo

  git_pull_status=$(git -C "$REPO_DIR" pull)

  echo "$git_pull_status" | grep --invert-match "Already up to date."

  test $? -eq 0

  is_local_repo_outdated="$?"
  if [ $is_local_repo_outdated -eq 0 ]; then
    echo "Repository updated."
    echo "Launching the script again..."
    "$0"
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

  "${REPO_DIR}"/utils/update_pacman_mirror_servers.sh
}

update_arch_linux_keyring() {
  echo "=============================="
  echo "Update Arch Linux keyring"
  echo " to avoid PGP signature errors"
  echo "=============================="

  PACMAN_GPG_DIR="/etc/pacman.d/gnupg"

  echo "===================================="
  echo "Backup current gpg configuration and"
  echo "Copy the embedded one"
  echo "------------------------------------"
  echo

  BACKUP_CONFIG_DIR="${CUSTOM_CONFIG_DIR}/gpg"
  mkdir --parents "${BACKUP_CONFIG_DIR}"
  sudo mv "${PACMAN_GPG_DIR}/gpg.conf" "${BACKUP_CONFIG_DIR}/gpg.conf-${BACKUP_TIME_AND_DATE}.bak"

  echo "======================"
  echo "Cleanup GPG keys"
  echo " see https://bbs.archlinux.org/viewtopic.php?pid=1837082#p1837082"
  echo "----------------------"
  echo

  sudo rm --force --recursive "${PACMAN_GPG_DIR}/"
  sudo rm --force --recursive "/root/.gnupg/"
  rm --force --recursive "${HOME}/.gnupg/"

  echo "========================="
  echo "Initialize pacman keyring"
  echo "-------------------------"
  echo

  sudo pacman-key --init

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
   
  echo "If the downloading of the graysky\'s GPG key hangs"
  echo "try downloading it from a different keyserver"
  echo
  echo "    sudo pacman-key --recv-keys 5EE46C4C --keyserver hkp://pool.sks-keyservers.net"

  sudo pacman-key --recv-keys 5EE46C4C
  sudo pacman-key --lsign-key 5EE46C4C

  #echo
  #echo "========================================"
  #echo "Add GPG key for 'post-factum' repository"
  #echo '(unofficial repo)'
  #echo "----------------------------------------"
  #echo

  #sudo pacman-key --keyserver hkp://pool.sks-keyservers.net --recv-keys 95C357D2AF5DA89D
  #sudo pacman-key --lsign-key 95C357D2AF5DA89D
 
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


  #linux-libre linux-libre-headers
  # AUR repo
  #gpg --recv-keys BCB7CF877E7D47A7
  #echo -ne 'y\n' | gpg --lsign-keys BCB7CF877E7D47A7
  #gpg --recv-keys 227CA7C556B2BA78
  #echo -ne 'y\n' | gpg --lsign-keys 227CA7C556B2BA78

  echo
  echo "==========================================================="
  echo "Uprade keyrings and additional mirrorlists for repositories"
  echo "-----------------------------------------------------------"
  echo

  pikaur \
      --sync \
      --refresh \
      --verbose \
      --noconfirm \
      --needed \
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
      --needed \
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
      --needed \
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

  "${REPO_DIR}"/utils/remount_boot_part_as_writable.sh
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
      --noconfirm \
      --needed \
      --config "${PACMAN_CUSTOM_CONFIG}" \
      --pikaur-config "${PIKAUR_CUSTOM_CONFIG}" \
    pikaur

  pikaur \
      --sync \
      --refresh \
      --noconfirm \
      --needed \
      --config "$PACMAN_CUSTOM_CONFIG" \
      --pikaur-config "$PIKAUR_CUSTOM_CONFIG" \
    reflector rsync shellcheck
}

check_script_syntax() {
  echo
  echo "================================="
  echo "Check script for syntactic errors"
  echo "================================="
  echo 

  # TODO test shellcheck analysis of all scripts in the entire repository
  #find "${REPO_DIR}" -type f -name "*.sh$" | xargs shellcheck
  find "${REPO_DIR}" -type f -name "*.sh" -exec shellcheck {} +
}

clear_pacman_database() {
  echo
  echo "==========================="
  echo "Clearing 'pacman' databases"
  echo "---------------------------"
  echo

  sudo rm -rf "${PACMAN_DB_PATH}/sync/*"
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
  clear_pacman_database
}

main
custom_config_dir
