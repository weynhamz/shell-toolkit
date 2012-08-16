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

__categories=(
    base
    al
    git
    dotploy
)

__scripts_base=(
    extclean.sh
    mencoder.sh
)
__scripts_al=(
    helper-al/makepkg.sh
    helper-al/logsplit.sh
    helper-al/epacman/epacman.sh
    helper-al/epacman/epacman-refresh.sh
)
__scripts_git=(
    helper-git/git-unpack.sh
    helper-git/git-fixtime.sh
    helper-git/git-editfile.sh
    helper-git/git-cmprange.sh
    helper-git/git-cleangit.sh
    helper-git/git-chparent.sh
    helper-git/git-subtree-extract.sh
)
__scripts_dotploy=(
    dotploy/dotploy.sh
)

dolink() {
    [ -h "$2" ] && rm -v $2
    ln -s $1 $2
}

deploy() {
    path=$1
    file=$(basename $path)
    srcp=$(_current_path)'/scripts/'$path
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

for __category in ${__categories[@]}; do
    # Use indirect variable reference here
    # @see http://unix.stackexchange.com/questions/20171
    _scripts='__scripts_'$__category'[@]'
    for __script in ${!_scripts}; do
        deploy $__script
    done
done

echo "Deployment finished, please add '$LOCAL_BIN' to your \$PATH environmental variable."
