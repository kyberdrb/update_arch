#!/bin/sh

set -e
set -x

sudo printf "\r"

PACMAN_DEFAULT_CONFIG_FILE="/etc/pacman.conf"
REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")"
BACKUP_DIR="${REPO_DIR}/backup"
mkdir --parents "${BACKUP_DIR}"
CUSTOM_LOG_DIR="${REPO_DIR}/logs"
BACKUP_TIME_AND_DATE=$(cat "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log")
sudo mv "${PACMAN_DEFAULT_CONFIG_FILE}" "${BACKUP_DIR}/pacman.conf-${BACKUP_TIME_AND_DATE}.bak"

CUSTOM_CONFIG_DIR="${REPO_DIR}/config"
PACMAN_CUSTOM_CONFIG="${CUSTOM_CONFIG_DIR}/pacman.conf"
sudo cp --force "${PACMAN_CUSTOM_CONFIG}" "$PACMAN_DEFAULT_CONFIG_FILE"








PIKAUR_CUSTOM_CONFIG="${CUSTOM_CONFIG_DIR}/pikaur.conf"
mv "${HOME}/.config/pikaur.conf" "${BACKUP_DIR}/pikaur.conf-${BACKUP_TIME_AND_DATE}.bak"
cp --force "$PIKAUR_CUSTOM_CONFIG" "${HOME}/.config/pikaur.conf"

PACMAN_LOG_FILE="$(pacman --verbose 2>/dev/null | grep "Log File" | rev | cut --delimiter=' ' --fields=1 | rev)"
wc -l "${PACMAN_LOG_FILE}" | cut -d' ' -f1 > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-pacman_log-starting_line_for_this_update_session.log"









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









# Download latest version of update script

#git_pull_status=$(git -C "${REPO_DIR}" pull)

#echo "$git_pull_status" | grep --invert-match "Already up to date."

#if [[ $? -eq 0 ]]; then
#  printf "%s\n" "Repository updated, or some merge problem occured."
#  printf "%s\n" "Check that and then please, launch the script again."
#  exit
#fi









# Download fresh list of mirror servers
"${REPO_DIR}"/utils/update_pacman_mirror_servers.sh









# Update Arch Linux keyring to avoid PGP signature interactive prompts or errors




# Backup current gpg configuration for pacman and
# copy embedded gpg configuration file to the system

PACMAN_GPG_DIR="$(pacman --verbose --config "${PACMAN_CUSTOM_CONFIG}" 2>/dev/null | grep "GPG Dir" | rev | cut --delimiter=' ' --fields=1 | rev)"

if [ -f "${PACMAN_GPG_DIR}gpg.conf" ]
then
  sudo mv "${PACMAN_GPG_DIR}gpg.conf" "${BACKUP_DIR}/gpg.conf-${BACKUP_TIME_AND_DATE}.bak"
fi




# Cleanup GPG keys
#  see https://bbs.archlinux.org/viewtopic.php?pid=1837082#p1837082"

if [ -d "${PACMAN_GPG_DIR}" ]; then
  sudo rm --recursive "${PACMAN_GPG_DIR}"
fi

if [ -d "/root/.gnupg/" ]; then
  sudo rm --recursive /root/.gnupg/
fi

if [ -d "${HOME}/.gnupg/" ]; then
  rm --recursive "${HOME}/.gnupg/"
fi




# Initialize pacman keyring

sudo pacman-key --init




# Backup default generated gpg.conf and copy custom gpg.conf


if [ -f "${PACMAN_GPG_DIR}gpg.conf" ]
then
  sudo mv "${PACMAN_GPG_DIR}gpg.conf" "${BACKUP_DIR}/gpg.conf-${BACKUP_TIME_AND_DATE}.bak"
fi

GPG_CUSTOM_CONFIG="${CUSTOM_CONFIG_DIR}/gpg.conf"
sudo cp --force "${GPG_CUSTOM_CONFIG}" "${PACMAN_GPG_DIR}gpg.conf"





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
sudo pacman-key --recv-keys 3056513887B78AEB
sudo pacman-key --lsign-key 3056513887B78AEB

# Add GPG key for Pedram Pourang - tsujan - required when building compton-conf AUR package - see https://aur.archlinux.org/packages/compton-conf/#pinned-742136
# Type: AUR repo
# Error code: 2 - gpg: no default secret key: No secret key Key not changed so no update needed.
gpg --recv-keys BE793007AD22DF7E
gpg2 --recv-keys BE793007AD22DF7E
#gpg --lsign-key BE793007AD22DF7E


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





  pikaur \
      --sync \
      --refresh \
      --noconfirm \
      --needed \
      --config "$PACMAN_CUSTOM_CONFIG" \
      --pikaur-config "$PIKAUR_CUSTOM_CONFIG" \
    pikaur reflector rsync shellcheck




# Remounting boot partition as writable in order to make the upgrade of kernel and other kernel dependend modules possible

"${REPO_DIR}"/utils/remount_boot_part_as_writable.sh







# Installing/Upgrading script dependencies

pikaur \
    --sync \
    --refresh \
    --noconfirm \
    --needed \
  pikaur


pikaur \
    --sync \
    --refresh \
    --noconfirm \
    --needed \
  expect







# Updating and upgrading packages

# Clear pacman databases

PACMAN_DB_PATH="$(pacman --verbose --config "${PACMAN_CUSTOM_CONFIG}" 2>/dev/null | grep "DB Path" | rev | cut --delimiter=' ' --fields=1 | rev)"
sudo rm -rf "$PACMAN_DB_PATH"/sync/*






# Updating official packages

sudo exo-open --launch TerminalEmulator --geometry=240x24 --display :0.0 --show-menubar --show-borders --hide-toolbar --command="pacman --sync --refresh --refresh --sysupgrade --needed --verbose --noconfirm" 2>&1 &






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

# TODO comment out 'ParallelDownloads' in '/etc/pacman.conf' to fix the untidy and unelegant output for DB syncing in pikaur
#   uncomment it after execution
#   and maybe make an alias for pacman (which uncomments the line before running) and pikaur (which comments out the line before running)

sudo exo-open --launch TerminalEmulator --geometry=240x24 --display :0.0 --show-menubar --show-borders --hide-toolbar --command="pikaur --sync --refresh --refresh --sysupgrade --verbose --noedit --nodiff --noconfirm --overwrite /usr/lib/p11-kit-trust.so --overwrite /usr/bin/fwupdate --overwrite /usr/share/man/man1/fwupdate.1.gz" 2>&1 &





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







# Wait for the pikaur window to close after done synchronizing databases and dropping the lock

sleep 5







# Removing leftovers

rm -rf ~/.libvirt







# Editing Chromium shortcut in order to disable (the annoying) gnome-keyring password prompt

"${REPO_DIR}/utils/chromium_disable_gnome-keyring_password_prompt.sh"








log_line_number_begin="$(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-pacman_log-starting_line_for_this_update_session.log")"
log_line_number_end="$(wc -l "$PACMAN_LOG_FILE" | cut -d' ' -f1)"
update_log_lines=$(( log_line_number_end - log_line_number_begin ))

printf "%s\n" "tac "${PACMAN_LOG_FILE}" | head --lines "${update_log_lines}" | less"








ln -sf "${REPO_DIR}/update_arch.sh" "${HOME}/update_arch.sh"
ln -sf "${REPO_DIR}/update_all_installed_ignored_packages.sh" "${HOME}/update_all_installed_ignored_packages.sh"
ln -sf "${REPO_DIR}/utils/remount_boot_part_as_writable.sh" "${HOME}/remount_boot_part_as_writable.sh"

