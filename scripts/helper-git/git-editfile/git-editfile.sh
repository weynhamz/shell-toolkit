#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

while getopts :bc:dfgmrs opt
do
    case $opt in
    'b')    backup="TRUE"
            ;;
    'c')    commit="$OPTARG"
            ;;
    'd')    dfedit="TRUE"
            ;;
    'f')    forced="TRUE"
            ;;
    'g')    giveup="TRUE"
            backup="TRUE"
            dfedit="TRUE"
            ;;
    'm')    backup="TRUE"
            dfedit="TRUE"
            ;;
    'r')    revert="TRUE"
            ;;
    's')    squash="TRUE"
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

if ! $(git ls-files | grep -q $file) && [ ! -n "$forced" ]; then
    echo "$file is not in git repository"
    exit 1
fi

if [ -n "$backup" ]; then
    if $(git ls-files -m | grep -q $file) || [ -n "$forced" ]; then
        backup $file && git co $file
    fi
    if [ -n "$giveup" ]; then
        backup $file && git co HEAD~ $file && git reset HEAD $file
    fi
elif [ -n "$revert" ]; then
    if $(git ls-files -m | grep -q $file) && [ ! -n "$forced" ]; then
        echo "$file has been modified";
        exit 1
    else
        revert $file
    fi
fi

if [ -n "$dfedit" ] && [ -f $file.bak ]; then
    if [ -n "$VIMBIN" ]; then
        editor=$VIMBIN
    else
        editor=vim
    fi
    $editor -d $file $file.bak
    exit 0
fi

if [ -n "$squash" ]; then
    commit="squash"
fi

if [ -n "$commit" ]; then
    git add $file
    git commit -m "$commit"
fi
