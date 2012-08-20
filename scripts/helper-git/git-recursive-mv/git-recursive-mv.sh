#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

help=$(cat << 'EOF'

Move file path in history.

Usage:

    git-recursive-mv.sh ([-a]|[-b <branch>]) -e <sed expression>

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

if [ -z "$sedexp" ]; then
    echo "Sed expresion not given"
    exit 1
fi

[ -n "$all" ] && range='-- --all' || range='HEAD'

[ -n "$branch" ] && range="$branch"

git filter-branch -f --index-filter 'git ls-files -s | sed "'$sedexp'" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE' $range
