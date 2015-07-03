#!/bin/bash

# # This script comes from here:
# # #     http://permalink.gmane.org/gmane.linux.arch.pacman.devel/11784
# # # To increase speed, it eschews some accuracy for speed. In detail, it
# # # ignores files aside with directories.
# #
# # shopt -s dotglob
# #
# # declare -A leafs=([/]=1)
# #
# # # Get all the directories
# # mapfile -t dirs < <(pacman -Qlq | grep '/$' | grep -v '^/dev' | grep -v '^/sys' | grep -v '^/run' | grep -v '^/tmp' | grep -v '^/mnt' | grep -v '^/srv' | grep -v '^/proc' | grep -v '^/boot' | grep -v '^/home' | grep -v '^/root' | grep -v '^/media' | grep -v '^/var/lib/pacman' | grep -v '^/var/cache/pacman' | grep -v '^/abs' | grep -v '^/nfs' | grep -v '^/host' | grep -v '^/grub' | grep -v '^/z_i686' | grep -v '^/opt/gnome' | sort -u)
# #
# # # Get all the directories that contain only files
# # # This is where the accuracy decreases, directories that contain directories are ignored.
# # for (( i = 0; i < ${#dirs[*]}; i++ )); do
# #   dir=${dirs[i]}
# #   parent=${dir%/*/}/
# #
# #   if [[ ${leafs["$parent"]} ]]; then
# #     unset leafs["$parent"]
# #     continue
# #   fi
# #
# #   leafs["$dir"]=1
# # done
# #
# # # Get all the files in the above directories
# # files=()
# # for l in "${!leafs[@]}"; do
# #   t=("$l"*)
# #   [[ -e $t ]] && files+=("${t[@]}")
# # done
# #
# # # Output the disowned files
# # printf '%s\n' "${files[@]}" | grep -vFf <(pacman -Qlq | grep -v '/$')

comm -23 <(sudo find / \( -path '/dev' -o -path '/sys' -o -path '/run' -o -path '/tmp' -o -path '/mnt' -o -path '/srv' -o -path '/proc' -o -path '/boot' -o -path '/home' -o -path '/root' -o -path '/media' -o -path '/var/lib/pacman' -o -path '/var/cache/pacman' -o -path '/abs' -o -path '/nfs' -o -path '/host' -o -path '/grub' -o -path '/z_i686' -o -path '/opt/gnome' \) -prune -o -type d -print | sed 's/\([^/]\)$/\1\//' | sort -u) <(pacman -Qlq | sort -u)

comm -23 <(sudo find / \( -path '/dev' -o -path '/sys' -o -path '/run' -o -path '/tmp' -o -path '/mnt' -o -path '/srv' -o -path '/proc' -o -path '/boot' -o -path '/home' -o -path '/root' -o -path '/media' -o -path '/var/lib/pacman' -o -path '/var/cache/pacman' -o -path '/abs' -o -path '/nfs' -o -path '/host' -o -path '/grub' -o -path '/z_i686' -o -path '/opt/gnome' \) -prune -o ! -type d -print | sort -u) <(pacman -Qlq | sort -u)
