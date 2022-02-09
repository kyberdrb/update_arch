#!/bin/sh

# TODO move to separate script to 'utils' dir

# Remove orphaned packages

# Step 1: Remove implicitly installed orphaned packages

# Backup pacman output for uninstallation of all orphaned packages

#-s, --recursive
#    Remove each target specified including all of their dependencies, provided that (A) they are not required by
#    other packages; and (B) they were not explicitly installed by the user. This operation is recursive and analogous
#    to a backwards --sync operation, and it helps keep a clean system without orphans. ...

if [ -z "$(sudo pacman --query --deps --unrequired --quiet)" ]
then

  # FOR PACMAN
  #sudo ./remove_orphaned_packages.sh.expect > /tmp/expect_output.log

  #tail --lines=-$(grep --line-number "Package" /tmp/expect_output.log | cut --delimiter=':' --fields=1) /tmp/expect_output.log | tail --lines=+3 | head --lines=-5 | tr --squeeze-repeats '[:space:]' | cut --delimiter=' ' --fields=1 | cut --delimiter='/' --fields=2

  # FOR PIKAUR
  #sudo ./remove_orphaned_packages.sh.expect > /tmp/expect_output.log

  #tail -n -$(grep --line-number "Repository packages will be installed" /tmp/expect_output.log | cut --delimiter=':' --fields=1) /tmp/expect_output.log | head -n -3 | tr --squeeze-repeats '[:space:]' | sed 's/^\s*//g' | cut --delimiter=' ' --fields=1 | strings | sed 's/\[0;1m//g'  | less

  yes n | sudo pacman --remove --nosave --recursive $(sudo pacman --query --deps --unrequired --quiet) 2>/dev/null 1> "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}-orphaned_packages-implicitly_installed_as_dependencies-pacman_output.log"






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
fi






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
