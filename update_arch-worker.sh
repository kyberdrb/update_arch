#!/bin/bash

set -e
set -x

sudo printf "\r"

PACMAN_DEFAULT_CONFIG_FILE="/etc/pacman.conf"
REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")"
BACKUP_DIR="${REPO_DIR}/backup"
mkdir --parents "${BACKUP_DIR}"
BACKUP_TIME_AND_DATE=$(cat "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log")
sudo mv "${PACMAN_DEFAULT_CONFIG_FILE}" "${BACKUP_DIR}/pacman.conf-${BACKUP_TIME_AND_DATE}.bak"


CUSTOM_CONFIG_DIR="${REPO_DIR}/config"
PACMAN_CUSTOM_CONFIG="${CUSTOM_CONFIG_DIR}/pacman.conf"
sudo cp --force "${PACMAN_CUSTOM_CONFIG}" "$PACMAN_DEFAULT_CONFIG_FILE"















# Set up pikaur

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

PIKAUR_CUSTOM_CONFIG="${CUSTOM_CONFIG_DIR}/pikaur.conf"
mv "${HOME}/.config/pikaur.conf" "${BACKUP_DIR}/pikaur.conf-${BACKUP_TIME_AND_DATE}.bak"
cp --force "$PIKAUR_CUSTOM_CONFIG" "${HOME}/.config/pikaur.conf"








# Download latest version of update script

git_pull_status=$(git -C "$REPO_DIR" pull)

echo "$git_pull_status" | grep --invert-match "Already up to date."

test $? -eq 0

is_local_repo_outdated="$?"
if [[ is_local_repo_outdated -eq 0 ]]; then
  printf "%s\n" "Repository updated, or some merge problem occured."
  printf "%s\n" "Check that and then please, launch the script again."
  exit
fi









# Download fresh list of mirror servers
"${REPO_DIR}"/utils/update_pacman_mirror_servers.sh









# Update Arch Linux keyring to avoid PGP signature interactive prompts or errors




# Copy embedded gpg configuration file to the system

PACMAN_GPG_DIR="$(pacman --verbose 2--config "${PACMAN_CUSTOM_CONFIG}" 2>/dev/null | grep "GPG Dir" | rev | cut --delimiter=' ' --fields=1 | rev)"
sudo mv "${PACMAN_GPG_DIR}gpg.conf" "${BACKUP_DIR}/gpg.conf-${BACKUP_TIME_AND_DATE}.bak"

GPG_CUSTOM_CONFIG="${CUSTOM_CONFIG_DIR}/gpg.conf"
sudo cp --force "${GPG_CUSTOM_CONFIG}" "${PACMAN_GPG_DIR}gpg.conf"





# Cleanup GPG keys
#  see https://bbs.archlinux.org/viewtopic.php?pid=1837082#p1837082"

sudo rm -R "$PACMAN_GPG_DIR"
sudo rm -R /root/.gnupg/
rm -rf ~/.gnupg/




# Initialize pacman keyring

sudo pacman-key --init

# Add GPG keys for custom repositories and AUR packages

sudo pacman-key --populate archlinux
sudo gpg --refresh-keys

# Add GPG key for seblu repository
# Type: unofficial repo
sudo pacman-key --recv-keys 76F3EB6DA1C5F938AD642DC438DCEEBE387A1EEE
sudo pacman-key --lsign-key 76F3EB6DA1C5F938AD642DC438DCEEBE387A1EEE

# Add GPG key for liquorix repository
# Type: unofficial repo
sudo pacman-key --recv-keys 9AE4078033F8024D
sudo pacman-key --lsign-key 9AE4078033F8024D

# Add GPG key for ck repository - graysky
# Type: unofficial repo
# If the downloading of the graysky GPG key hangs try downloading it from a different keyserver"
# e.g.
# sudo pacman-key --recv-keys 5EE46C4C --keyserver hkp://pool.sks-keyservers.net"
sudo pacman-key --recv-keys 5EE46C4C
sudo pacman-key --lsign-key 5EE46C4C

# Add GPG key for chaotic repository - Pedro Henrique Lara Campos - pedrohlc
# Type: unofficial repo
sudo pacman-key --keyserver hkp://pool.sks-keyservers.net --recv-keys 3056513887B78AEB
sudo pacman-key --lsign-key 3056513887B78AEB

# Add GPG key for Pedram Pourang - tsujan - required when building compton-conf AUR package - see https://aur.archlinux.org/packages/compton-conf/#pinned-742136
# Type: AUR repo
gpg --recv-keys BE793007AD22DF7E
gpg --lsign-key BE793007AD22DF7E


# Uprade keyrings and additional mirrorlists for repositories

pikaur \
  --sync \
  --refresh --refresh \
  --verbose \

pikaur \
    --sync \
    --refresh \
    --verbose \
    --noconfirm \
  archlinux-keyring

# Update chaotic-mirrorlists
# chaotic-mirrorlist adds separate mirrorlist file in
# /etc/pacman.d/chaotic-mirrorlist

pikaur \
    --sync \
    --refresh \
    --verbose \
    --noconfirm \
  chaotic-mirrorlist

# Update chaotic-keyring which adds GPG keys for chaotic-aur repo
# For chaotic-aur repo setup, see https://lonewolf.pedrohlc.com/chaotic-aur/

pikaur \
    --sync \
    --refresh \
    --verbose \
    --noconfirm \
  chaotic-keyring 











# Remounting boot partition as writable in order to make the upgrade of kernel and other kernel dependend modules possible

"${REPO_DIR}"/utils/remount_boot_part_as_writable.sh








# Installing/Upgrading script dependencies

pikaur \
    --sync \
    --refresh \
    --needed \
    --noconfirm \
    --config "$PACMAN_CUSTOM_CONFIG" \
    --pikaur-config "$PIKAUR_CUSTOM_CONFIG" \
  pikaur powerpill reflector rsync shellcheck









# Updating and upgrading packages

# Clear pacman databases

PACMAN_DB_PATH="$(pacman --verbose 2--config "${PACMAN_CUSTOM_CONFIG}" 2>/dev/null | grep "DB Path" | rev | cut --delimiter=' ' --fields=1 | rev)"
sudo rm -rf "$PACMAN_DB_PATH"/sync/*






# Updating official packages

sudo exo-open --launch TerminalEmulator --geometry=240x24 --display :0.0 --show-menubar --show-borders --hide-toolbar --hold --command="pacman --sync --refresh --refresh --sysupgrade --needed --verbose --noconfirm" 2>&1






# wait for the lock
while [ ! -f "/var/lib/pacman/db.lck" ]
do
  sleep 1
done

while [ -f "/var/lib/pacman/db.lck" ]
do
  # wait for the drop of the lock to proceed
  if [ ! -f "/var/lib/pacman/db.lck" ]
  then
    break
  fi

  sleep 1
done






# Updating unofficial - AUR - packages

sudo exo-open --launch TerminalEmulator --geometry=240x24 --display :0.0 --show-menubar --show-borders --hide-toolbar --hold --command="pikaur --sync --refresh --refresh --sysupgrade --verbose --noedit --nodiff --noconfirm --overwrite /usr/lib/p11-kit-trust.so --overwrite /usr/bin/fwupdate --overwrite /usr/share/man/man1/fwupdate.1.gz" 2>&1





# wait for the lock
while [ ! -f "/var/lib/pacman/db.lck" ]
do
  sleep 1
done

while [ -f "/var/lib/pacman/db.lck" ]
do
  # wait for the drop of the lock to proceed
  if [ ! -f "/var/lib/pacman/db.lck" ]
  then
    break
  fi

  sleep 1
done











# Removing leftovers

rm -rf ~/.libvirt

# Remove orphaned packages

# Step 1: Remove implicitly installed orphaned packages

# Backup pacman output for uninstallation of all orphaned packages

#-s, --recursive
#    Remove each target specified including all of their dependencies, provided that (A) they are not required by
#    other packages; and (B) they were not explicitly installed by the user. This operation is recursive and analogous
#    to a backwards --sync operation, and it helps keep a clean system without orphans. ...

yes n | sudo pacman --remove --nosave --recursive $(sudo pacman --query --deps --unrequired --quiet) > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies-pacman_output.log" 2>/dev/null






# Save all orphaned packages that were installed implicitly (automatically), as a dependency for other packages

sudo pacman --query --deps --unrequired --quiet > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies.log"





# Uninstall all orphaned packages that were installed implicitly (automatically), as a dependency for other packages

number_of_implicitly_installed_dependencies="$(wc -l "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies.log" | cut --delimiter=' ' --fields=1)"

if [ $number_of_implicitly_installed_dependencies -ge 1 ]
then
  sudo pacman --remove --nosave --recursive --noconfirm $(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies.log")
fi



# Install back optionally required orphaned packages

grep 'optionally requires' "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies-pacman_output.log" | tr -d ':' | sed 's/^\s*//g' | cut --delimiter=' ' --fields=4 > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies-still_required_as_optional_dependencies_for_other_packages.log"

pikaur --sync --refresh --refresh --needed --noedit --nodiff --noconfirm $(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies-still_required_as_optional_dependencies_for_other_packages.log")






# Step 2: Remove explicitly installed orphaned packages

# Save pacman output for uninstallation of all orphaned packages, even the explicitly (manually) installed

#REMOVE OPTIONS (APPLY TO -R)
#...
#-s, --recursive
#    ... if you want to omit condition (B), pass this option twice.

yes n | sudo pacman --remove --nosave --recursive --recursive $(sudo pacman --query --deps --unrequired --quiet) > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-pacman_output.log" 2>/dev/null






# Save all orphaned packages that were explicitly (manually) installed

head -n -2 "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-pacman_output.log" | tail -n +5 | tr --squeeze-repeats '[:space:]' | cut --delimiter=' ' --fields=1 > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages_explicitly_installed.log"







# Uninstall all orphaned packages that were installed explicitly (manually), as a dependency for other packages

number_of_explicitly_installed_dependencies="$(wc -l "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages_explicitly_installed.log" | cut --delimiter=' ' --fields=1)"

if [ $number_of_explicitly_installed_dependencies -ge 1 ]
then
  sudo pacman --remove --nosave --recursive --noconfirm $(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages_explicitly_installed.log")
fi









# Install back optionally required explicitly installed orphaned packages

grep 'optionally requires' "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-pacman_output.log" | tr -d ':' | sed 's/^\s*//g' | cut --delimiter=' ' --fields=4 > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-still_required_as_optional_dependencies_for_other_packages.log"

number_of_explicitly_installed_optional_dependencies="$(wc -l "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-still_required_as_optional_dependencies_for_other_packages.log" | cut --delimiter=' ' --fields=1)"

if [ $number_of_explicitly_installed_optional_dependencies -ge 1 ]
then
  pikaur --sync --refresh --refresh --needed --noedit --nodiff --noconfirm $(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-still_required_as_optional_dependencies_for_other_packages.log")
fi






# Editing Chromium shortcut in order to disable (the annoying) gnome-keyring password prompt

"${REPO_DIR}/utils/chromium_disable_gnome-keyring_password_prompt.sh"








log_line_number_begin="$(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-pacman_log-starting_line_for_this_update_session.log")"
PACMAN_LOG_FILE="$(pacman --verbose 2--config "${PACMAN_CUSTOM_CONFIG}" 2>/dev/null | grep "Log File" | rev | cut --delimiter=' ' --fields=1 | rev)"
log_line_number_end="$(wc -l "$PACMAN_LOG_FILE" | cut -d' ' -f1)"
update_log_lines=$(( log_line_number_end - log_line_number_begin ))
tail -n "$update_log_lines" "${PACMAN_LOG_FILE}" | less








ln -sf "${REPO_DIR}/update_arch.sh" "${HOME}/update_arch.sh"
ln -sf "${REPO_DIR}/update_all_installed_ignored_packages.sh" "${HOME}/update_all_installed_ignored_packages.sh"
ln -sf "${REPO_DIR}/utils/remount_boot_part_as_writable.sh" "${HOME}/remount_boot_part_as_writable.sh"

