#!/bin/sh

sudo echo -e "\r"

array=( $(grep --line-number "Exec" /usr/share/applications/chromium.desktop | grep --invert-match "\-\-password\-store=basic" | cut -d':' -f1) )

for exec_line_number in "${array[@]}"
do
  sudo sed --in-place "${exec_line_number}s/$/ --password-store=basic/" /usr/share/applications/chromium.desktop
done

# https://unix.stackexchange.com/questions/70878/replacing-string-based-on-line-number/70879#70879
# https://stackoverflow.com/questions/9449417/how-do-i-assign-the-output-of-a-command-into-an-array/9449633#9449633
# https://www.tutorialkart.com/bash-shell-scripting/bash-array/
# Alternate method (not recommended): https://www.ricksdailytips.com/prevent-chrome-from-asking-for-a-password-with-ubuntu/
