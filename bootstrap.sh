#!/bin/bash
#
# Deploy these scripts into personal binary directory
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

dolink() {
    [ -h "$2" ] && rm -v $2
    ln -s -v $1 $2
}

deploy() {
    path=$1
    file=$(basename $path)
    srcp=$(_current_path)'/'$path
    dest=$LOCAL_BIN'/'$file
    if [ -h $dest ]; then
        cdst=$(realpath $dest 2>/dev/null)
        if [ -n "$cdst" ]; then
            [ "$cdst" != "$srcp" ] && echo "$dest is link to $cdst, not $srcp"
        else
            echo "$dest is broken, link it to $srcp"
            dolink $srcp $dest
        fi
    elif [ -e $dest ]; then
        echo "Unkown type $dest has already exited, leave it alone"
    else
        dolink $srcp $dest
    fi
}

if [ ! -n "$LOCAL_BIN" ]; then
    LOCAL_BIN=$HOME'/.local/bin'
fi

mkdir -p $LOCAL_BIN

for __script in $(find scripts/ -type f -name "*.sh" | grep -v "tests/" | grep -v ".repo/"); do
    [ -x $__script ] && deploy $__script
done

echo "Deployment finished, please add '$LOCAL_BIN' to your \$PATH environmental variable."
