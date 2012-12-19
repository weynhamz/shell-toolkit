#!/bin/bash
#
#Get the entire git repo of the specfic Arch Package Build

git svn clone -s svn://svn.archlinux.org/$1/$2 2> /dev/null
until [ $? -eq 0 ]; do
git svn clone -s svn://svn.archlinux.org/$1/$2 2> /dev/null
done
