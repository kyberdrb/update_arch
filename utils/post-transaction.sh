#!/bin/sh

SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"

echo
echo "=================="
echo "Removing leftovers"
echo "=================="

rm -rf "${HOME}/.libvirt"

# TODO execute orphans removal in the "Removing leftovers" section

echo "=========================================="
echo "Editing Chromium shortcut in order"
echo "to disable 'gnome-keyring' password prompt"
echo "------------------------------------------"

"${SCRIPT_DIR}/chromium_disable_gnome-keyring_password_prompt.sh"

echo "=========================================="

ln -sf "${SCRIPT_DIR}/post-transaction.sh" "$HOME/post-transaction.sh"
ln -sf "${SCRIPT_DIR}/../update_all_installed_ignored_packages.sh" "$HOME/update_all_installed_ignored_packages.sh"
ln -sf "${SCRIPT_DIR}/remount_boot_part_as_writable.sh" "$HOME/remount_boot_part_as_writable.sh"

echo "A link to the update scripts and to remounting script"
echo "have been made in your home directory"
echo "for more convenient launching at"
echo
echo "${HOME}/${post-transaction_script_name}"
echo "${HOME}/update_all_installed_ignored_packages.sh"
echo "${HOME}/remount_boot_part_as_writable.sh"
echo "------------------------------------------"
echo

