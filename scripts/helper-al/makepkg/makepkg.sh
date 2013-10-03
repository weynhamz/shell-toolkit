#!/bin/bash

[ -f PKGBUILD ] || exit 1

source ./PKGBUILD
source /etc/makepkg.conf
source $HOME/.makepkg.conf

[ -n "$pkgbase" ] || pkgbase=$pkgname

if [ -n "$BUILDDIR" ]
then
    mkdir -p $BUILDDIR/$pkgbase
    SRCDEST=$BUILDDIR/$pkgbase /usr/bin/makepkg "$@"
else
    /usr/bin/makepkg "$@"
fi
