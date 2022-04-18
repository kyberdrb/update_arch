#!/bin/sh

CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION="${1%.*}"

# Remove orphaned packages

# Step 1: Remove implicitly installed orphaned packages

# Backup pacman output for uninstallation of all orphaned packages

#-s, --recursive
#    Remove each target specified including all of their dependencies, provided that (A) they are not required by
#    other packages; and (B) they were not explicitly installed by the user. This operation is recursive and analogous
#    to a backwards --sync operation, and it helps keep a clean system without orphans. ...

if [ -z "$(sudo pacman --query --deps --unrequired --quiet)" ]
then

  yes n | sudo pacman --remove --nosave --recursive $(sudo pacman --query --deps --unrequired --quiet) 1> "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-implicitly_installed_as_dependencies-pacman_output.log" 2>/dev/null

  # ===

  # Save all orphaned packages that were installed implicitly (automatically), as a dependency for other packages
  sudo pacman --query --deps --unrequired --quiet > "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-implicitly_installed_as_dependencies.log"

  # ===

  # Uninstall all orphaned packages that were installed implicitly (automatically), as a dependency for other packages

  number_of_implicitly_installed_dependencies="$(wc -l "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-implicitly_installed_as_dependencies.log" | cut --delimiter=' ' --fields=1)"

  if [ $number_of_implicitly_installed_dependencies -ge 1 ]
  then
    sudo pacman --remove --nosave --recursive --noconfirm $(cat "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-implicitly_installed_as_dependencies.log")
  fi

  # ===

  # Install back optionally required orphaned packages

  grep 'optionally requires' "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-implicitly_installed_as_dependencies-pacman_output.log" | tr -d ':' | sed 's/^\s*//g' | cut --delimiter=' ' --fields=4 > "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-implicitly_installed_as_dependencies-still_required_as_optional_dependencies_for_other_packages.log"

  pikaur --sync --refresh --refresh --needed --noedit --nodiff --noconfirm $(cat "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-implicitly_installed_as_dependencies-still_required_as_optional_dependencies_for_other_packages.log")

  # ===
  # ===
  # ===

  # Step 2: Remove explicitly installed orphaned packages

  # Save pacman output for uninstallation of all orphaned packages, even the explicitly (manually) installed

  #REMOVE OPTIONS (APPLY TO -R)
  #...
  #-s, --recursive
  #    Remove each target specified including all of their dependencies, provided that ... (B) they were not explicitly installed by the user. ... if you want to omit condition (B), pass this option twice.

  yes n | sudo pacman --remove --nosave --recursive --recursive $(sudo pacman --query --deps --unrequired --quiet) > "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-explicitly_installed-pacman_output.log" 2>/dev/null

  # ===

  # Save all orphaned packages that were explicitly (manually) installed

  head -n -2 "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-explicitly_installed-pacman_output.log" | tail -n +5 | tr --squeeze-repeats '[:space:]' | cut --delimiter=' ' --fields=1 > "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages_explicitly_installed.log"

  # ===

  # Uninstall all orphaned packages that were installed explicitly (manually), as a dependency for other packages

  number_of_explicitly_installed_dependencies="$(wc -l "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages_explicitly_installed.log" | cut --delimiter=' ' --fields=1)"

  if [ $number_of_explicitly_installed_dependencies -ge 1 ]
  then
    sudo pacman --remove --nosave --recursive --noconfirm $(cat "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages_explicitly_installed.log")
  fi

  # ===

  # Install back optionally required explicitly installed orphaned packages

  grep 'optionally requires' "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-explicitly_installed-pacman_output.log" | tr -d ':' | sed 's/^\s*//g' | cut --delimiter=' ' --fields=4 > "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-explicitly_installed-still_required_as_optional_dependencies_for_other_packages.log"

  number_of_explicitly_installed_optional_dependencies="$(wc -l "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-explicitly_installed-still_required_as_optional_dependencies_for_other_packages.log" | cut --delimiter=' ' --fields=1)"

  if [ $number_of_explicitly_installed_optional_dependencies -ge 1 ]
  then
    pikaur --sync --refresh --refresh --needed --noedit --nodiff --noconfirm $(cat "${CUSTOM_LOG_FILE_FILENAME_WITHOUT_EXTENSION}-orphaned_packages-explicitly_installed-still_required_as_optional_dependencies_for_other_packages.log")
  fi
fi
