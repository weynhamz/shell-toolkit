#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:

git filter-branch --prune-empty --index-filter "git rm -r --cached --ignore-unmatch $1" -- --all
