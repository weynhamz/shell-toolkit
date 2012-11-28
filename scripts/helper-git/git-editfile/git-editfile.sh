#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

help=$(cat << 'EOF'

A helper script for easily editing and commiting changes into git.

    git-editfile.sh [-f] [-b] [-d] [-m] [-g] [-r] [-c <commit message>] [-s] <file>

    <file> arg could be any were in the options list. For the convenient of
    changing the flags, the following form is more usefull.

    git-editfile.sh <file> [-f] [-b] [-d] [-m] [-g] [-r] [-c <commit message>] [-s]

Options:

    -f  Force the operation if not in a git repo
        Force backup if file has not been changed
        Force revert if file has been changed
    -b  Backup <file> to <file>.bak
    -d  Edit <file> and <file>.bak in vim diff mode
    -m  Backup first, then diff edit the file
    -g  Revert the changes introduced by <file> in the prefious
        commit, the changed file were saved to <file>.bak
    -r  Revert <file>.bak to <file>
    -c  Commit <file> with <commit message>
    -s  Commit <file> with message 'squash' for later rebasing.
    -h  Show the help message

EOF
)

while [ $# -gt 0 ]
do
    case $1 in
    '-b')   backup="TRUE"
            ;;
    '-c')   commit="$2"
            shift
            ;;
    '-d')   dfedit="TRUE"
            ;;
    '-f')   forced="TRUE"
            ;;
    '-g')   giveup="TRUE"
            backup="TRUE"
            dfedit="TRUE"
            ;;
    '-m')   backup="TRUE"
            dfedit="TRUE"
            ;;
    '-r')   revert="TRUE"
            ;;
    '-s')   squash="TRUE"
            ;;
    '-h')   echo "$help"
            exit 0
            ;;
      -*)
            arg=$1
            arg_2=${arg#-?}
            if [ -n "$arg_2" ]; then
                shift
                arg_1=${arg%$arg_2}
                args_new=$arg' '$arg_1' -'$arg_2' '"$@"
                echo $args_new
                set -- $args_new
            else
                echo "Invalid Arg"
                echo "$help"
                exit 1
            fi
            ;;
       *)   [ -z "$file" ] && file="$1" || {
                echo "File has been specified: $file, $1 is not valid."
                exit 1
            }
            ;;
    esac
    shift
done

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
