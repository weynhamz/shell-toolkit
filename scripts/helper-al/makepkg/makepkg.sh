#!/bin/bash

[ -f PKGBUILD ] || exit 1

BUILDROOT=/home/abs/builds

source ./PKGBUILD

[ -n "$pkgbase" ] && BUILDDIR=$BUILDROOT/$pkgbase || BUILDDIR=$BUILDROOT/$pkgname

mkdir -p $BUILDDIR

cp * $BUILDDIR

cd $BUILDDIR

makepkg $@
