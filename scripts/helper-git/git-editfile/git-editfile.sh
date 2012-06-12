#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

while getopts :bdmr opt
do
    case $opt in
    'b')    backup="TRUE"
            ;;
    'd')    dfedit="TRUE"
            ;;
    'm')    backup="TRUE"
            dfedit="TRUE"
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
    [ ! -f $file ] && return 0
    if [ -f $file.bak ] && ! $(cmp -s $file $file.bak); then
        backup $file.bak
    fi
    cp $file $file.bak
}

revert() {
    local file=$1
    mv $file.bak $file
    if [ -f $file.bak.bak ]; then
        revert $file.bak
    fi
}

file=$1

if ! $(git ls-files | grep -q $file); then
    echo "$file is not in git repository"
    exit 1
fi

if [ -n "$backup" ]; then
    if $(git ls-files -m | grep -q $file); then
        backup $file && git co $file
    fi
elif [ -n "$revert" ]; then
    if $(git ls-files -m | grep -q $file); then
        echo "$file has been modified";
        exit 1
    else
        revert $file
    fi
fi

if [ -n "$dfedit" ] && [ -f $file.bak ]; then
    vim -d $file $file.bak
    exit 0
fi
