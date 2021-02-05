#!/bin/bash

SCRIPT_DIR="$(dirname $(readlink --canonicalize $0))"

request_sudo_password() {
  sudo echo

  echo "================================================================================"
  echo "Script location"
  echo " $SCRIPT_DIR"
  echo "================================================================================"
  echo
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
  sudo cp --dereference /etc/pacman.conf /etc/pacman.conf-${BACKUP_TIME_AND_DATE}.bak

  echo "====================================================="
  echo "Link embedded pacman configuration file to the system"
  echo "-----------------------------------------------------"
  echo

  sudo ln -sf "${SCRIPT_DIR}"/config/pacman.conf /etc/pacman.conf
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
    cd /tmp/pikaur-git/pikaur-git
    makepkg --ignorearch --clean --syncdeps --noconfirm
    PIKAUR_PACKAGE_NAME=$(ls -- *.tar*)
    sudo pacman --upgrade --noconfirm --config "${SCRIPT_DIR}"/config/pacman.conf "$PIKAUR_PACKAGE_NAME"
    rm -rf /tmp/pikaur-git
  fi

  echo "================================================="
  echo "'pikaur' package installed"
  echo 'Arch User Repository (AUR) Package Helper present'
  echo "-------------------------------------------------"
  echo 
}

update_repo_of_this_script() {
  echo "========================================"
  echo "Download latest version of update script"
  echo "========================================"
  echo

  local git_pull_status=$(git -C "$(dirname $(readlink -f ~/update_arch.sh))" pull)

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

  sudo rm -R /etc/pacman.d/gnupg/
  sudo rm -R /root/.gnupg/
  rm -rf ~/.gnupg/

  echo "========================="
  echo "Initialize pacman keyring"
  echo "-------------------------"
  echo

  sudo pacman-key --init
  echo "keyserver hkp://keyserver.ubuntu.com" | sudo tee --append "/etc/pacman.d/gnupg/gpg.conf"


  echo
  echo "====================================================="
  echo "Add GPG keys for custom repositories and AUR packages"
  echo "-----------------------------------------------------"
  echo

  sudo pacman-key --populate archlinux
  sudo gpg --refresh-keys

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

  pikaur --sync --refresh --refresh --verbose --config "${SCRIPT_DIR}"/config/pacman.conf --pikaur-config "${SCRIPT_DIR}"/config/pikaur.conf --pikaur-config "${SCRIPT_DIR}"/config/pikaur.conf

  pikaur --sync --refresh --verbose --noconfirm --config "${SCRIPT_DIR}"/config/pacman.conf --pikaur-config "${SCRIPT_DIR}"/config/pikaur.conf archlinux-keyring

  echo 
  echo "====================================================="
  echo "'chaotic-mirrorlist' adds separate mirrorlist file in"
  echo "  /etc/pacman.d/chaotic-mirrorlist"
  echo "-----------------------------------------------------"
  echo

  pikaur --sync --refresh --verbose --noconfirm --config "${SCRIPT_DIR}"/config/pacman.conf --pikaur-config "${SCRIPT_DIR}"/config/pikaur.conf chaotic-mirrorlist

  echo
  echo "====================================================="
  echo "'chaotic-keyring' add GPG keys for 'chaotic-aur' repo"
  echo "-----------------------------------------------------"
  echo "For chaotic-aur repo setup, see page"
  echo "  https://lonewolf.pedrohlc.com/chaotic-aur/"
  echo "-----------------------------------------------------"
  echo

  pikaur --sync --refresh --verbose --noconfirm --config "${SCRIPT_DIR}"/config/pacman.conf --pikaur-config "${SCRIPT_DIR}"/config/pikaur.conf chaotic-keyring 
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

  pikaur --sync --refresh --needed --noconfirm --config "${SCRIPT_DIR}"/config/pacman.conf --pikaur-config "${SCRIPT_DIR}"/config/pikaur.conf pikaur powerpill reflector rsync
}

upgrade_packages() {
  echo
  echo "==============================="
  echo "Updating and upgrading packages"
  echo "==============================="
  echo 

  echo "========================"
  echo "Clear 'pacman' databases"
  echo "------------------------"
  echo

  sudo rm -rf /var/lib/pacman/sync/*

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
    --config "${SCRIPT_DIR}"/config/pacman.conf \
    --pikaur-config "${SCRIPT_DIR}"/config/pikaur.conf 2>&1)

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

    sudo powerpill \
        --sync \
        --refresh --refresh \
        --sysupgrade --sysupgrade \
        --needed \
        --verbose \
        --noconfirm \
        --config "${SCRIPT_DIR}"/config/pacman.conf \
        --powerpill-config "${SCRIPT_DIR}"/config/powerpill.json

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
        --config "${SCRIPT_DIR}"/config/pacman.conf \
        --pikaur-config "${SCRIPT_DIR}"/config/pikaur.conf \
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

  echo "=========================================="
  echo
  echo Please, reboot to apply updates 
  echo for kernel, firmware, graphics drivers 
  echo or other drivers and services 
  echo requiring service restart or system reboot.
  echo
  echo "------------------------------------------"
  echo
  echo "But if something went wrong"
  echo " check the configurations"
  echo " and the pacman log with"
  echo "  less /var/log/pacman.log"
  echo

  echo "TODO show the pacman log"
  echo "only for the last run"
  echo "with 'grep -n' and 'tail'"
  echo "from the first line matching to"
  echo " 'date "+%Y-%m-%dT%H:%M:XX%z"'"
  echo "until the end"
  echo '(maybe by calculating the difference'
  echo "between total line count and"
  echo 'line number of the grepped date + 1)'
  echo
  echo "=========================================="
  echo

  ln -sf "$(readlink --canonicalize $0)" "$HOME/$(basename $0)"
  ln -sf "${SCRIPT_DIR}/utils/remount_boot_part_as_writable.sh" "$HOME/remount_boot_part_as_writable.sh"

  echo "A link to the update script and to remounting script"
  echo "have been made in your home directory at"
  echo
  echo "  $(ls $HOME/$(basename $0))"
  echo
  echo "and"
  echo
  echo "  $(ls $HOME/remount_boot_part_as_writable.sh)"
  echo
  echo "for more convenient launching"
  echo
}

main() {
  request_sudo_password
  set_up_pacman_configuration 
  set_up_pikaur
  update_repo_of_this_script
  update_pacman_mirror_servers
  update_arch_linux_keyring
  remount_boot_partition_as_writable
  install_script_dependencies
  upgrade_packages
  clean_up
  finalize
}

main

