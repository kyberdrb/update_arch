#!/bin/sh

#set -e
set -x

sudo printf "\r"

CUSTOM_LOG_FILE_FOR_UPDATE="${1}"

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

# Remove DB lock to prevent hiccups
DB_LOCK_FILE="$(pacman --verbose 2>/dev/null | grep "Lock File" | rev | cut --delimiter=' ' --fields=1 | rev)"
sudo rm --force "${DB_LOCK_FILE}"

# Set up pikaur

# Install 'debugedit' package to prevent errors when installing AUR packages:
#  :: Starting the build:
#  ==> ERROR: Cannot find the debugedit binary required for including source files in debug packages.
#  Command 'sudo --user=#1000 -- makepkg --force' failed to execute.

sudo pacman --sync --refresh --needed --noconfirm debugedit

# TODO below piece of code is also encapsulated in 'utils/update_eID_klient.sh'
#  compare, abstract, extract and centralize duplicate code?

PIKAUR_INSTALLED=$(pacman --query | grep pikaur)
if [ -z "${PIKAUR_INSTALLED}" ]
then 
  temporary_pikaur_dir_path="/tmp/pikaur-git/"
  rm -rf "${temporary_pikaur_dir_path}"
  git clone https://aur.archlinux.org/pikaur-git.git "${temporary_pikaur_dir_path}"
  cd "${temporary_pikaur_dir_path}"
  makepkg --ignorearch --clean --syncdeps --install --noconfirm
  pacman_cache_dir="$(pacman --verbose 2>/dev/null | grep "Cache Dirs" | cut --delimiter=':' --fields=2 | sed 's/^\s*//g' | tr --squeeze-repeats ' ' | cut --delimiter=' ' --fields=1)"
  find "${temporary_pikaur_dir_path}" -mindepth 1 -maxdepth 1 -type f -name "*.zst" -exec sudo mv --verbose "{}" "${pacman_cache_dir}" \;
  rm -rf "${temporary_pikaur_dir_path}"
  cd "${REPO_DIR}"
fi

# Download latest version of update script

# disable exitting on failure, i.e. non-zero return code
set +e

git_pull_status=$(git -C "${REPO_DIR}" pull)

echo "$git_pull_status" | grep --invert-match "Already up to date."

if [[ $? -eq 0 ]]; then
  printf "%s\n" "Repository updated, or some merge problem occured."
  printf "%s\n" "Check it, fix it, and launch the script again."
  exit
fi

# enable exitting on failure again?
set -e

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
sudo gpg --refresh-keys --allow-weak-key-signatures

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
gpg --recv-keys --allow-weak-key-signatures BE793007AD22DF7E
gpg2 --recv-keys --allow-weak-key-signatures BE793007AD22DF7E
#gpg --lsign-key --allow-weak-key-signatures BE793007AD22DF7E


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

# TODO - TEST THIS CONDITION: Switch to new chaotic-mirrorlist file, when available
#  to make sure the package database from chaotic servers will be downloaded entirely

if [ -e "/etc/pacman.d/chaotic-mirrorlist.pacnew" ]
then
    sudo mv "/etc/pacman.d/chaotic-mirrorlist" "/etc/pacman.d/chaotic-mirrorlist-${BACKUP_TIME_AND_DATE}.bak"
    sudo cp "/etc/pacman.d/chaotic-mirrorlist.pacnew" "/etc/pacman.d/chaotic-mirrorlist"
fi

# Update chaotic-keyring which adds GPG keys for chaotic-aur repo
#  For chaotic-aur repo setup, see https://lonewolf.pedrohlc.com/chaotic-aur/
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
    --noconfirm \
    --needed \
  pikaur-git

# Updating and upgrading packages

# Clear pacman databases

PACMAN_DB_PATH="$(pacman --verbose --config "${PACMAN_CUSTOM_CONFIG}" 2>/dev/null | grep "DB Path" | rev | cut --delimiter=' ' --fields=1 | rev)"
sudo rm -rf "${PACMAN_DB_PATH}sync/*"

# Remove orphaned packages
sudo "${REPO_DIR}/utils/remove_orphaned_packages.sh" "${CUSTOM_LOG_FILE_FOR_UPDATE}"

# Update official packages

# I know there is a more elegant solution here
#     https://www.shellcheck.net/wiki/SC2089 - Quotes/backslashes will be treated literally. Use an array.
#   but I'll stick with the 'if/else' solution for now for simplicity:
#   less layers of abstraction and direct command execution - immediately readable and, hopefully, understandable

echo "Upgrade commands:"
echo "sudo pacman --sync --refresh --refresh --sysupgrade --needed --verbose --noconfirm"
echo "pikaur --sync --refresh --refresh --sysupgrade --verbose --noedit --nodiff --noconfirm --overwrite /usr/lib/p11-kit-trust.so --overwrite /usr/bin/fwupdate --overwrite /usr/share/man/man1/fwupdate.1.gz"

bash_pid=$$
ps -o comm= -p $bash_pid
script_pid=$(ps -o ppid= -p $bash_pid)
ps -o comm= -p $script_pid
script_bash_pid=$(ps -o ppid= -p $script_pid)
ps -o comm= -p $script_bash_pid
another_pid=$(ps -o ppid= -p $script_bash_pid)
ps -o comm= -p $another_pid
TERMINAL_EMULATOR=$(ps -o comm= -p $another_pid)

if [ "${XDG_SESSION_TYPE}" = "x11" ]
then
  sudo ${TERMINAL_EMULATOR} --geometry=189x24 --command="sudo pacman --sync --refresh --refresh --sysupgrade --needed --verbose --noconfirm"
else
  sudo pacman --sync --refresh --refresh --sysupgrade --needed --verbose --noconfirm
fi

# Update unofficial - AUR - packages

if [ "${XDG_SESSION_TYPE}" = "x11" ]
then
  sudo "${TERMINAL_EMULATOR}" --geometry=189x24 --command="pikaur --sync --refresh --refresh --sysupgrade --verbose --noedit --nodiff --noconfirm --overwrite /usr/lib/p11-kit-trust.so --overwrite /usr/bin/fwupdate --overwrite /usr/share/man/man1/fwupdate.1.gz"
else
  pikaur --sync --refresh --refresh --sysupgrade --verbose --noedit --nodiff --noconfirm --overwrite /usr/lib/p11-kit-trust.so --overwrite /usr/bin/fwupdate --overwrite /usr/share/man/man1/fwupdate.1.gz
fi

# Removing leftovers
rm -rf ~/.libvirt

# Editing Chromium shortcut in order to disable (the annoying) gnome-keyring password prompt
"${REPO_DIR}/utils/chromium_disable_gnome-keyring_password_prompt.sh"

# Restore HDMI audio delay fix in pulseaudio default configuration
# Fix for audio delay from HDMI output when I start playing audio
#   play audio immediately from HDMI output after starting playback of audio or video
#   see `pulseaudio` package https://github.com/kyberdrb/installed_packages_linux/blob/master/README.md
sudo sed --in-place 's/^load-module module-suspend-on-idle/#load-module module-suspend-on-idle/g' "/etc/pulse/default.pa"

log_line_number_begin="$(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-pacman_log-starting_line_for_this_update_session.log")"
log_line_number_end="$(wc -l "$PACMAN_LOG_FILE" | cut -d' ' -f1)"
update_log_lines=$(( log_line_number_end - log_line_number_begin ))

printf "%s\n" "tac "${PACMAN_LOG_FILE}" | head --lines "${update_log_lines}" | less"

ln -sf "${REPO_DIR}/update_arch.sh" "${HOME}/update_arch.sh"
ln -sf "${REPO_DIR}/update_all_installed_ignored_packages.sh" "${HOME}/update_all_installed_ignored_packages.sh"
ln -sf "${REPO_DIR}/utils/remount_boot_part_as_writable.sh" "${HOME}/remount_boot_part_as_writable.sh"

