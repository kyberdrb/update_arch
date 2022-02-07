#!/bin/sh

set -x

echo
echo "=================="
echo "Removing leftovers"
echo "=================="
echo

rm -rf "${HOME}/.libvirt"

echo "========================"
echo "Remove orphaned packages"
echo "========================"
echo

REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")/.."
CUSTOM_LOG_DIR="${REPO_DIR}/logs"
BACKUP_TIME_AND_DATE=$(cat "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log")

echo "========================================================================="
echo "                    Remove orphaned packages: Step 1"
echo "-------------------------------------------------------------------------"
echo "Remove orphans (orphaned packages) that were"
echo "implicitly (automatically) installed (as dependencies for other packages)"
echo "-------------------------------------------------------------------------"
echo

#-s, --recursive
#    Remove each target specified including all of their dependencies, provided that (A) they are not required by
#    other packages; and (B) they were not explicitly installed by the user. This operation is recursive and analogous
#    to a backwards --sync operation, and it helps keep a clean system without orphans. ...


echo "================================================================"
echo "Backup pacman output for uninstallation of all orphaned packages"
echo "----------------------------------------------------------------"
echo

yes n | sudo pacman --remove --nosave --recursive $(sudo pacman --query --deps --unrequired --quiet) > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies-pacman_output.log" 2>/dev/null

echo "=============================================================="
echo "Save all orphaned packages that were installed"
echo "implicitly (automatically), as a dependency for other packages"
echo "--------------------------------------------------------------"
echo

sudo pacman --query --deps --unrequired --quiet > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies.log"

echo "=============================================================="
echo "Uninstall all orphaned packages that were installed"
echo "implicitly (automatically), as a dependency for other packages"
echo "--------------------------------------------------------------"
echo

number_of_implicitly_installed_dependencies="$(wc -l "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies.log" | cut --delimiter=' ' --fields=1)"

if [ $number_of_implicitly_installed_dependencies -ge 1 ]
then
  sudo pacman --remove --nosave --recursive --noconfirm $(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies.log")
fi

echo "=================================================="
echo "Install back optionally required orphaned packages"
echo "--------------------------------------------------"
echo

grep 'optionally requires' "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies-pacman_output.log" | tr -d ':' | sed 's/^\s*//g' | cut --delimiter=' ' --fields=4 > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies-still_required_as_optional_dependencies_for_other_packages.log"

pikaur --sync --refresh --refresh --needed --noedit --nodiff --noconfirm $(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies-still_required_as_optional_dependencies_for_other_packages.log")

echo
echo "========================================================="
echo "              Remove orphaned packages: Step 2"
echo "---------------------------------------------------------"
echo "Remove orphans that were explicitely (manually) installed"
echo "except the optionally required packages"
echo "---------------------------------------------------------"
echo

#REMOVE OPTIONS (APPLY TO -R)
#...
#-s, --recursive
#    ... if you want to omit condition (B), pass this option twice.

echo "================================================================="
echo "Backup pacman output for uninstallation of all orphaned packages,"
echo "even the explicitly (manually) installed"
echo "-----------------------------------------------------------------"
echo

yes n | sudo pacman --remove --nosave --recursive --recursive $(sudo pacman --query --deps --unrequired --quiet) > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-pacman_output.log" 2>/dev/null

echo "===================================================================="
echo "Save all orphaned packages that were explicitly (manually) installed"
echo "--------------------------------------------------------------------"
echo

head -n -2 "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-pacman_output.log" | tail -n +5 | tr --squeeze-repeats '[:space:]' | cut --delimiter=' ' --fields=1 > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages_explicitly_installed.log"

echo "========================================================="
echo "Uninstall all orphaned packages that were installed"
echo "explicitly (manually), as a dependency for other packages"
echo "---------------------------------------------------------"
echo

number_of_explicitly_installed_dependencies="$(wc -l "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages_explicitly_installed.log" | cut --delimiter=' ' --fields=1)"

if [ $number_of_explicitly_installed_dependencies -ge 1 ]
then
  sudo pacman --remove --nosave --recursive --noconfirm $(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages_explicitly_installed.log")
fi

echo "======================================================================="
echo "Install back optionally required explicitly installed orphaned packages"
echo "-----------------------------------------------------------------------"
echo

grep 'optionally requires' "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-pacman_output.log" | tr -d ':' | sed 's/^\s*//g' | cut --delimiter=' ' --fields=4 > "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-still_required_as_optional_dependencies_for_other_packages.log"

number_of_explicitly_installed_optional_dependencies="$(wc -l "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-still_required_as_optional_dependencies_for_other_packages.log" | cut --delimiter=' ' --fields=1)"

if [ $number_of_explicitly_installed_optional_dependencies -ge 1 ]
then
  pikaur --sync --refresh --refresh --needed --noedit --nodiff --noconfirm $(cat "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-explicitly_installed-still_required_as_optional_dependencies_for_other_packages.log")
fi

# Sources:
# - https://wiki.archlinux.org/title/Pacman/Tips_and_tricks#Removing_unused_packages_(orphans)
# - https://duckduckgo.com/?q=script+echo+into+ineractive+bash&ia=web
# - https://duckduckgo.com/?q=Pass+input+to+interactive+command+line+program+in+bash&ia=web
# - https://www.baeldung.com/linux/bash-interactive-prompts

echo
echo "=========================================="
echo "Editing Chromium shortcut in order"
echo "to disable 'gnome-keyring' password prompt"
echo "------------------------------------------"
echo

"${REPO_DIR}/utils/chromium_disable_gnome-keyring_password_prompt.sh"

