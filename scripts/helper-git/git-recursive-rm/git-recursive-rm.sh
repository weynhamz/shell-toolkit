#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:

help=$(cat << 'EOF'

Remove a file through the whole history.

Usage:

    git-recursive-rm.sh ([-a]|[-b <branch>]) [-d] <file>

Options:

    -a Filter on all branches
    -b Branch to be filtered on
    -d Output the command
EOF
)

while getopts :ab:dh opt
do
    case $opt in
    'a')    all=TRUE
            ;;
    'b')    branch=$OPTARG
            ;;
    'd')    debug=TRUE
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

file=$1

if [ ! -e ".git" ]; then
    echo "require to be run at root of the git repo"
    exit 1
fi

[ -n "$all" ] && range='-- --all' || range='HEAD'

[ -n "$branch" ] && range="$branch"

cmd='git filter-branch -f --prune-empty --index-filter '\''git rm -r --cached --ignore-unmatch "'$file'"'\'' '$range

[ -n "$debug" ] && echo $cmd || {
    eval "$cmd"
}
