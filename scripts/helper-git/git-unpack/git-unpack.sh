#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:

# Pack and prune all loose objects at first
git gc --prune=now

# Unpack to the loose objects
rm .git/objects/info/* &&
mv .git/objects/pack/* . &&
git-unpack-objects < *.pack &&
rm -fv pack-*.*

# Update ref files
mkdir -p .git/refs/tags
mkdir -p .git/refs/heads
for remote in `git remote`;do
    mkdir -p .git/refs/remotes/$remote
done
cat .git/packed-refs | grep -v '^#' | sed 's/^/echo /g' | sed 's: refs/: > .git/refs/:g' | bash && rm .git/packed-refs

# Update repo status
git-update-server-info
