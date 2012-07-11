#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:

read -ra range1 <<< $(git rev-list --reverse $1)
read -ra range2 <<< $(git rev-list --reverse $2)

range1l=${#range1[@]}
range2l=${#range2[@]}

[ $range1l -lt $range2l ] && max=$range1l || max=$range2l

i=0
while [ $i -lt $max ];do
    echo "git diff ${range1[$i]} ${range2[$i]}"
    git dft ${range1[$i]} ${range2[$i]}
    i=$((++i))
    read -p "Press any key to continue..." -n1 -s
    echo
done
