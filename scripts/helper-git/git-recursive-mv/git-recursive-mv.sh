#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

help=$(cat << 'EOF'

Move file to another location through the whole history.

Usage:

    git-recursive-mv.sh ([-a]|[-b <branch>]) -e <sed expression> <source path> <dest path>

Options:

    -a Filter on all branches
    -b Branch to be filtered on
    -e Sed expression
EOF
)

while getopts :ab:e:h opt
do
    case $opt in
    'a')    all=TRUE
            ;;
    'b')    branch=$OPTARG
            ;;
    'e')    sedexp=$OPTARG
            ;;
    'h')    echo "$help"
            exit 0
            ;;
      ?)    echo "invalid arg"
            echo "$help"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if [ ! -e ".git" ]; then
    echo "require to be run at root of the git repo"
    exit 1
fi

if [ -z "$sedexp" ]; then
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "source or dest file must be set."
        echo "$help"
        exit 1
    else
        src_path=$1
        dst_path=$2

        if [[ $dst_path == . ]] || [[ $dst_path =~ ^.*/$ ]]
        then
            dst_path=${dst_path%%/}
            filename=${src_path##*/}
            if [ $dst_path == '.' ]
            then
                dst_path=$filename
            else
                dst_path=${dst_path}/$filename
            fi

        fi

        src_path=${src_path//\//\\\/}
        dst_path=${dst_path//\//\\\/}

        sedexp="s/\t$src_path/\t$dst_path/g"
    fi
fi

[ -n "$all" ] && range='-- --all' || range='HEAD'

[ -n "$branch" ] && range="$branch"

cmd='git filter-branch -f --prune-empty --index-filter '\''git ls-files -s | sed "'$sedexp'" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE'\'' '$range

eval "$cmd"
