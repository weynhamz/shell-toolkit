#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

help=$(cat << 'EOF'

Change parent to a specific commit.

Usage:

    git-chparent.sh ([-a]|[-b <branch>]) -p <parent revision> <target revision>

Options:

    -a Filter on all branches
    -b Branch to be filtered on
    -p Reference of the new parent commit
EOF
)

while getopts :ab:p:h opt
do
    case $opt in
    'a')    all=TRUE
            ;;
    'b')    branch=$OPTARG
            ;;
    'p')    parent_commit=$(git rev-parse $OPTARG)
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

target_commit=$(git rev-parse $1)

[ -n "$all" ] && range='-- --all' || range='HEAD'

[ -n "$branch" ] && range="$branch"

git filter-branch -f --parent-filter 'test $GIT_COMMIT = '$target_commit' && echo "-p '$parent_commit'" || cat' $range
