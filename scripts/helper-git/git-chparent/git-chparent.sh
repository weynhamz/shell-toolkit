#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

while getopts :p: opt
do
    case $opt in
    'p')    parent_commit=$(git rev-parse $OPTARG)
            ;;
      ?)    echo "invalid arg"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

target_commit=$(git rev-parse $1)

git filter-branch -f --parent-filter 'test $GIT_COMMIT = '$target_commit' && echo "-p '$parent_commit'" || cat' -- --all
