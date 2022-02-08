#!/bin/sh

set -x

REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")"

"${REPO_DIR}/utils/remount_boot_part_as_writable.sh"

CUSTOM_LOG_DIR="${REPO_DIR}/logs"
BACKUP_TIME_AND_DATE=$(date "+%Y_%m_%d-%H_%M_%S")

locally_installed_ignored_packages_for_upgrade="$(pacman --query --quiet $(cat /etc/pacman.conf | grep IgnorePkg | cut -d '=' -f2) 2>/dev/null | tr '\n' ' ')"

sudo exo-open --launch TerminalEmulator --geometry=240x24 --display :0.0 --show-menubar --show-borders --hide-toolbar --hold --command="pacman --sync --refresh --refresh --needed --verbose --noconfirm ${locally_installed_ignored_packages_for_upgrade}" 2>&1

# wait until the pacman db lock is acquired
#  in order to prevent multiple accesses to the pacman database
#  because only one program can use the pacman database

while [ ! -f "/var/lib/pacman/db.lck" ]
do
  sleep 1
done

# when the lock for pacman databse is acquired
#  wait until the program drops this lock.
#  Then we can access to the pacman database with another program safely

while [ -f "/var/lib/pacman/db.lck" ]
do
  if [ ! -f "/var/lib/pacman/db.lck" ]
  then
    break
  fi

  sleep 1
done

sudo exo-open --launch TerminalEmulator --geometry=240x24 --display :0.0 --show-menubar --show-borders --hide-toolbar --hold --command="pikaur --sync --refresh --refresh --needed --verbose --noedit --nodiff --noconfirm ${locally_installed_ignored_packages_for_upgrade}" 2>&1

