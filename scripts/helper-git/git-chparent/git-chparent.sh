#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

while getopts :p: opt
do
    case $opt in
    'p')    parent_commit=$OPTARG
            ;;
      ?)    echo "invalid arg"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

git filter-branch -f --parent-filter 'test $GIT_COMMIT = '$1' && echo "-p '$parent_commit'" || cat' -- --all
