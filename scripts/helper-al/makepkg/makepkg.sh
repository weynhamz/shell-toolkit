#!/bin/bash

[ -f PKGBUILD ] || exit 1

WORKSPACE=$(pwd)
BUILDROOT=/home/abs/builds

source ./PKGBUILD

[ -n "$pkgbase" ] && BUILDDIR=$BUILDROOT/$pkgbase || BUILDDIR=$BUILDROOT/$pkgname

mkdir -p $BUILDDIR

cd $BUILDDIR

# Remove old files
touch HOLDER && \
rm $(ls -1 --color=none | grep -v -e '^pkg$' -e '^src$' -e '^.*\.pkg\.tar\.xz$' -e '^.*\.src\.tar\.gz$')

cp $WORKSPACE/* .

makepkg $@
