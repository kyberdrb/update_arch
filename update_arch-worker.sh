#!/bin/sh

set -x

UPDATE_ALL_IGNORED_PACKAGES=$1

get_terminal_emulator() {
    pid=$$
    while [ "$pid" -gt 1 ]; do
        pid=$(cat /proc/$pid/stat | cut -d ' ' -f 4)
        exe=$(readlink -f /proc/$pid/exe 2>/dev/null) || continue

        # A terminal emulator owns a pseudo-terminal master (ptmx)
        if ls -la /proc/$pid/fd 2>/dev/null | grep -q ptmx; then
            echo "$exe"
            return 0
        fi
    done
    return 1
}

run_in_terminal() {
    cmd="$1"
    term_exe=$(get_terminal_emulator) || { echo "Cannot detect terminal emulator" >&2; return 1; }
    term_name=$(basename "$term_exe")

    EXIT_FILE=$(mktemp)

    case "$term_name" in
        kitty)
            # -o overrides config: 'c' suffix means cells (columns/rows)
            sudo -E "$term_exe" \
                -o initial_window_width=189c \
                -o initial_window_height=24c \
                sh -c "$cmd; echo \$? > ${EXIT_FILE}"
            return $?
            ;;
        xfce4-terminal)
            sudo -E "$term_exe" --geometry=189x24 --command="sh -c \"$cmd; echo \$? > ${EXIT_FILE}\""
            return $?
            ;;
        *)
            echo "Unsupported terminal emulator: $term_name" >&2
            return 2
            ;;
    esac

    _ret=$(cat "${EXIT_FILE}" 2>/dev/null)
    rm -f "${EXIT_FILE}"
    return "${_ret:-1}"
}

# Update official packages

# I know there is a more elegant solution here
#     https://www.shellcheck.net/wiki/SC2089 - Quotes/backslashes will be treated literally. Use an array.
#   but I'll stick with the 'if/else' solution for now for simplicity:
#   less layers of abstraction and direct command execution - immediately readable and, hopefully, understandable

echo "Upgrade commands:"
echo "sudo pacman --sync --refresh --refresh --sysupgrade --needed --verbose --noconfirm"
echo "pikaur --sync --refresh --refresh --sysupgrade --verbose --noedit --nodiff --noconfirm --overwrite /usr/lib/p11-kit-trust.so --overwrite /usr/bin/fwupdate --overwrite /usr/share/man/man1/fwupdate.1.gz"

#bash_pid=$$
#ps -o comm= -p $bash_pid
#script_pid=$(ps -o ppid= -p $bash_pid)
#ps -o comm= -p $script_pid
#script_bash_pid=$(ps -o ppid= -p $script_pid)
#ps -o comm= -p $script_bash_pid
#another_pid=$(ps -o ppid= -p $script_bash_pid)
#ps -o comm= -p $another_pid
#TERMINAL_EMULATOR=$(ps -o comm= -p $another_pid)

#echo "$$"
#PARENT_TERMINAL_PID=$(ps -o ppid= -p "$$" | tr -d ' ')
#echo "${PARENT_TERMINAL_PID}"
#TERMINAL_BINARY_NAME="$(ps -p "${PARENT_TERMINAL_PID}" -o comm=)"
#echo "${TERMINAL_BINARY_NAME}"
#TERMINAL_EMULATOR=$(readlink -f /proc/${TERMINAL_BINARY_NAME}/exe)
#echo "${TEMRINAL_EMULATOR}"

#exit
# UNREACHABLE CODE

#if [ "${XDG_SESSION_TYPE}" = "x11" ]
#then
#  sudo ${TERMINAL_EMULATOR} --geometry=189x24 --command="sudo pacman --sync --refresh --refresh --sysupgrade --needed --verbose --noconfirm"
#else
#  sudo pacman --sync --refresh --refresh --sysupgrade --needed --verbose --noconfirm
#fi

# Update unofficial - AUR - packages

#if [ "${XDG_SESSION_TYPE}" = "x11" ]
#then
#  sudo "${TERMINAL_EMULATOR}" --geometry=189x24 --command="pikaur --sync --refresh --refresh --sysupgrade --verbose --noedit --nodiff --noconfirm --overwrite /usr/lib/p11-kit-trust.so --overwrite /usr/bin/fwupdate --overwrite /usr/share/man/man1/fwupdate.1.gz"
#else
#  pikaur --sync --refresh --refresh --sysupgrade --verbose --noedit --nodiff --noconfirm --overwrite /usr/lib/p11-kit-trust.so --overwrite /usr/bin/fwupdate --overwrite /usr/share/man/man1/fwupdate.1.gz
#fi

echo "${KITTY_WINDOW_ID}"
echo $(get_terminal_emulator)

run_in_terminal "pacman --sync --refresh --refresh --sysupgrade --needed --verbose --noconfirm"

run_in_terminal "pikaur --sync --refresh --refresh --sysupgrade --verbose --noedit --nodiff --noconfirm --overwrite /usr/lib/p11-kit-trust.so --overwrite /usr/bin/fwupdate --overwrite /usr/share/man/man1/fwupdate.1.gz"

if [ "${UPDATE_ALL_IGNORED_PACKAGES}" == "--update-ignored" ] || \
   [ "${UPDATE_ALL_IGNORED_PACKAGES}" == "-i" ]
then
  #REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")"
  #"${REPO_DIR}/update_all_installed_ignored_packages.sh

  locally_installed_ignored_packages_for_upgrade="$(pacman --query --quiet $(cat "/etc/pacman.conf" | grep "IgnorePkg" | cut -d '=' -f2) 2>/dev/null | tr '\n' ' ')"
  
  #run_in_terminal "pacman --sync --refresh --refresh --needed --verbose --noconfirm ${locally_installed_ignored_packages_for_upgrade}"

  #run_in_terminal "pikaur --sync --refresh --refresh --needed --verbose --noedit --nodiff --noconfirm ${locally_installed_ignored_packages_for_upgrade}"

  # FOR DEBUGGING PURPOSES
  for ignored_package in ${locally_installed_ignored_packages_for_upgrade}
  do
    echo "${ignored_package}"
  done

  for ignored_package in ${locally_installed_ignored_packages_for_upgrade}
  do
    if run_in_terminal "pacman --sync --refresh --refresh --needed --verbose --noconfirm ${ignored_package}"
    then
      run_in_terminal "pikaur --sync --refresh --refresh --needed --verbose --noedit --nodiff --noconfirm ${ignored_package}"
    fi
  done
fi

set +x

