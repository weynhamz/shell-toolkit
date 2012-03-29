#!/bin/bash

#
# Get current directory
#
# From: http://stackoverflow.com/questions/59895
#
_current_path() {
    SOURCE="${BASH_SOURCE[0]}"
    DIR="$( dirname "$SOURCE" )"
    while [ -h "$SOURCE" ]
    do
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
        DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
    done
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    echo $DIR
}

if [ -n "$1" ];then
	hostname=$1
elif [ -n "$HOSTNAME" ];then
	hostname=$HOSTNAME
else
	echo "HOSTNAME must not be empty!"
fi

$(_current_path)'/epacman.sh' -e -o -f $hostname.epkgs
$(_current_path)'/epacman.sh' -d -o -f $hostname.dpkgs
