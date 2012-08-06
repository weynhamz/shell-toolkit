#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

git reflog expire --expire=now --all

refbak=$(git for-each-ref --format="%(refname)" refs/original/)
if [ -n "$refbak" ];then
    echo -n $refbak | xargs -n 1 git update-ref -d
fi

git repack -a -d
