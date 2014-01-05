#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:

[ ! -e "$1" ] && echo "$1 does not exist!" && exit 1

git clone --no-hardlinks $1 $2

cd $2

for branch in `git branch -a | sed 's/^\s*//' | grep remotes | grep -v HEAD | grep -v master`; do
    git branch --track ${branch#remotes/origin/} $branch
done

git filter-branch --subdirectory-filter $2 --prune-empty --tag-name-filter cat -- --all

git reset --hard

git remote rm origin
