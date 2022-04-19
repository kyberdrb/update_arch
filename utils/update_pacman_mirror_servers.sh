#!/bin/sh

set -x

update_pacman_mirror_servers() {
  echo "================================"
  echo "Searching for fastest mirrors..."
  echo "--------------------------------"

  echo
  echo "======================================================="
  echo "Downloading current status of Arch Linux mirror servers"
  echo "-------------------------------------------------------"
  echo

  # The easy way ^_^ that sometimes fails
  #pikaur \
  #    --sync \
  #    --refresh \
  #    --verbose \
  #    --noconfirm \
  #    --needed
  #  reflector
  #
  # reflector --fastest 200 --sort rate --completion-percent 100 --verbose --country Slovakia,Czechia,Poland,Hungary,Ukraine,Austria,Germany | tee ~/reflector_mirrorlist
  # local number_of_lines_reflector_mirrorlist
  # number_of_lines_reflector_mirrorlist=$(wc -l ~/reflector_mirrorlist | cut -d' ' -f1)
  # local number_of_intro_lines
  # number_of_intro_lines=10
  # number_of_mirrors=$((number_of_lines_reflector_mirrorlist - number_of_intro_lines))
  # tail -n $number_of_mirrors ~/reflector_mirrorlist > ~/reflector_mirrorlist-clean

  # ===================================================================================

  # The hard way `_´ that always works and is fastah, better, strongur ºOº &) :D :)
  #  Because doing things by hand is always 'better' and 'more efficient' right? Right?? No? Ok, maybe not... :/ :D
  curl -L "https://www.archlinux.org/mirrors/status/" -o ~/Arch_Linux-Mirrors-Status.html

  echo
  echo "==============================================="
  echo "Finding the table with the fully synced mirrors"
  echo "-----------------------------------------------"
  echo
  
  echo "============================"
  echo "Calculating table boundaries"
  echo "----------------------------"
  echo

  SUCCESSFUL_MIRRORS_TABLE_BEGINNING_LINE=$(cat ~/Arch_Linux-Mirrors-Status.html | grep -n -m 1 successful_mirrors | cut -d':' -f1)

  SUCCESSFUL_MIRRORS_TABLE_ENDING_LINE=$(cat ~/Arch_Linux-Mirrors-Status.html | grep -n -m 2 "/table" | tail -n 1 | cut -d':' -f1)

  ALL_LINES_COUNT=$(cat ~/Arch_Linux-Mirrors-Status.html | wc -l)
  TAIL_LIMIT=$(( ALL_LINES_COUNT - SUCCESSFUL_MIRRORS_TABLE_BEGINNING_LINE + 1 ))
  HEAD_LIMIT=$(( SUCCESSFUL_MIRRORS_TABLE_ENDING_LINE - SUCCESSFUL_MIRRORS_TABLE_BEGINNING_LINE + 1 ))

  echo "==============================================="
  echo "Cropping only the table with successful mirrors"
  echo "-----------------------------------------------"
  echo

  cat ~/Arch_Linux-Mirrors-Status.html | tail -n $TAIL_LIMIT | head -n $HEAD_LIMIT > ~/Arch_Linux-Mirrors-Status-Successful_Mirrors_Table_Only.html

  echo "====================================="
  echo "Transforming HTML table to CSV format"
  echo "-------------------------------------"
  echo

  cat ~/Arch_Linux-Mirrors-Status-Successful_Mirrors_Table_Only.html | sed '/<a href/d' | sed 's/^[\ \t]*//g' | grep -i -e "<td\|<tr>" | sed 's/<tr>//Ig'| sed '/^$/d' | sed 's/<\/td>/,/Ig' | sed 's/<td>//Ig' | sed 's/span /\n/Ig' | sed 's/<\/span> /\n/Ig' | sed '/^<td class/d' | sed '/^class/d' | tr --delete '\n' | sed 's/<\/tr>/\n/Ig' | sed 's/,$//g' | grep '100.0%' | grep "Slovakia\|Czechia\|Poland\|Hungary\|Ukraine\|Austria\|\Germany" > ~/mirrorlist.csv

  echo "========================================================="
  echo "Extracting only the URLs of the servers from the CSV file"
  echo "---------------------------------------------------------"
  echo

  while IFS= read -r line
  do
    echo "$line" | cut -d',' -f1 | tee --append ~/mirrorlist
  done < ~/mirrorlist.csv

  echo
  echo "========================================================"
  echo "Make the 'mirrorlist' file a valid and usable for pacman"
  echo "--------------------------------------------------------"
  echo

  echo "============================="
  echo "Adding prefix for each server"
  echo "-----------------------------"
  echo

  sed -i 's/^/Server = /g' ~/mirrorlist

  echo "============================="
  echo "Adding suffix for each server"
  echo "-----------------------------"
  echo

  sed -i 's/$/\$repo\/os\/\$arch/g' ~/mirrorlist

  echo "=========================================="
  echo "Printing a piece of the final 'mirrorlist'"
  echo "------------------------------------------"
  echo

  cat ~/mirrorlist | head

  echo
  echo "============================="
  echo "Backing up current pacman mirrorlist"
  echo " /etc/pacman.d/mirrorlist"
  echo "-----------------------------"
  echo

  BACKUP_TIME_AND_DATE=$(date "+%Y_%m_%d-%H_%M_%S")
  sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-${BACKUP_TIME_AND_DATE}.bak

  echo "====================================================="
  echo "Current 'mirrorlist' Backed up mirrorlist file is located at"
  echo " /etc/pacman.d/mirrorlist-${BACKUP_TIME_AND_DATE}.bak"
  echo "-----------------------------------------------------"
  echo
  
  echo "================================================================"
  echo "Moving new 'mirrorlist' to the pacman directory to apply changes"
  echo "----------------------------------------------------------------"
  echo

  #TODO if ~/reflector_mirrorlist file is not empty
  # i.e. if it has more than one line by 'wc -l'
  # use the reflector's mirrorlist

  #TODO instead of saving the 'mirrorlist' in the home directory '~'
  # save in the 'config' directory in this repo
  # and link the '/etc/pacman.d/mirrorlist' file 
  # to the 'mirrorlist' file in this repo

  sudo mv ~/mirrorlist /etc/pacman.d/mirrorlist

  echo "==========="
  echo "Cleaning up"
  echo "-----------"
  echo

  rm ~/mirrorlist.csv
  rm ~/Arch_Linux-Mirrors-Status-Successful_Mirrors_Table_Only.html
  rm ~/Arch_Linux-Mirrors-Status.html
}

main() {
  update_pacman_mirror_servers
}

main

