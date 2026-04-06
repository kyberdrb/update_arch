#!/bin/sh

set -x

# Removing leftovers
rm -rf ~/.libvirt

REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")"

# Editing Chromium shortcut in order to disable (the annoying) gnome-keyring password prompt
"${REPO_DIR}/utils/chromium_disable_gnome-keyring_password_prompt.sh"

# Restore HDMI audio delay fix in pulseaudio default configuration
# Fix for audio delay from HDMI output when I start playing audio
#   play audio immediately from HDMI output after starting playback of audio or video
#   see `pulseaudio` package https://github.com/kyberdrb/installed_packages_linux/blob/master/README.md
sudo sed --in-place 's/^load-module module-suspend-on-idle/#load-module module-suspend-on-idle/g' "/etc/pulse/default.pa"

CUSTOM_LOG_DIR="${REPO_DIR}/logs"
log_line_number_begin="$(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-pacman_log-starting_line_for_this_update_session.log")"

PACMAN_LOG_FILE="$(pacman --verbose 2>/dev/null | grep "Log File" | rev | cut --delimiter=' ' --fields=1 | rev)"
log_line_number_end="$(wc -l "${PACMAN_LOG_FILE}" | cut -d' ' -f1)"
update_log_lines=$(( log_line_number_end - log_line_number_begin ))

printf "%s\n" "tac "${PACMAN_LOG_FILE}" | head --lines "${update_log_lines}" | less"

ln -sf "${REPO_DIR}/update_arch.sh" "${HOME}/update_arch.sh"
ln -sf "${REPO_DIR}/update_all_installed_ignored_packages.sh" "${HOME}/update_all_installed_ignored_packages.sh"
ln -sf "${REPO_DIR}/utils/remount_boot_part_as_writable.sh" "${HOME}/remount_boot_part_as_writable.sh"

set +x

