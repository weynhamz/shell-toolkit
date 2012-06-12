#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

while getopts :dmr opt
do
    case $opt in
    'd')    dfedit="TRUE"
            ;;
    'm')    modify="TRUE"
            ;;
    'r')    revert="TRUE"
            ;;
      ?)    echo "Invalid Arg"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

backup() {
    local file=$1
    cp $file $file.bak
}

revert() {
    local file=$1
    mv $file.bak $file
}

file=$1

if [ -n "$modify" ]; then
    backup $file && git co $file
elif [ -n "$revert" ]; then
    revert $file
fi

if [ -n "$dfedit" ] && [ -f $file.bak ]; then
    vim -d $file $file.bak
    exit 0
fi
