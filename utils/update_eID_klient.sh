#!/bin/sh

eidklient_aur_repo_path="/tmp/eidklient/"
rm -rf "${eidklient_aur_repo_path}"
git clone https://aur.archlinux.org/eidklient.git "${eidklient_aur_repo_path}"

axel --verbose --num-connections=5 \
    https://eidas.minv.sk/downloadservice/eidklient/linux/eID_klient_x86_64.tar.gz \
    --output="${eidklient_aur_repo_path}eID_klient_x86_64.tar.gz"

cd "${eidklient_aur_repo_path}"
makepkg --ignorearch --clean --syncdeps --install --noconfirm --needed

pacman_cache_dir="$(pacman --verbose 2>/dev/null | grep "Cache Dirs" | cut --delimiter=':' --fields=2 | sed 's/^\s*//g' | tr --squeeze-repeats ' ' | cut --delimiter=' ' --fields=1)"
find "${eidklient_aur_repo_path}" -mindepth 1 -maxdepth 1 -type f -name "*.zst" -exec sudo mv --verbose "{}" "/var/cache/pacman/pkg/" \;

rm --recursive --force "${eidklient_aur_repo_path}"
