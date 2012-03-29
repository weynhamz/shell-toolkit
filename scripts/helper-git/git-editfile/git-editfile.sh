#!/bin/bash

while getopts :mr opt
do
    case $opt in
    'm')    modify="TRUE"
            ;;
    'r')    revert="TRUE"
            ;;
    '?')    echo "Invalid Arg"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

file=$1

if [ -n "$modify" ]; then
    cp $file $file.bak && git co $file
    vimdiff $file $file.bak
elif [ -n "$revert" ]; then
    mv $file.bak $file
fi
