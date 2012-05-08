#!/bin/sh
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

while getopts :acd:frt opt
do
    case $opt in
    'd')    date=$(LC_ALL=C date -R --date="$OPTARG")
            [ $? -eq 1 ] && exit 1
            ;;
    'a')    change_author_date="TRUE"
            ;;
    'c')    change_committer_date="TRUE"
            ;;
    'f')    fix_committer_date_cmd='&& export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE'
            ;;
    'r')    isrange="TRUE"
            ;;
    't')    debug="TRUE"
            ;;
    '?')    echo "Invalid Arg"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

range=' -- --all'

test_cmd='cat'

if [ -n "$1" ];then
    if [ -n "$isrange" ];then
        set -- $(git rev-list $1)
    fi
    first=1
    test_cmd='('
    while [ -n "$1" ];do
        commit=$1
        [ $first -eq 0 ] && test_cmd=$test_cmd' || '
        test_cmd=$test_cmd'test $GIT_COMMIT = "'$commit'"'
        first=0
        shift
    done
    test_cmd=$test_cmd')'
fi

if [ -n "$date" ];then
    if [ -z "$commit" ] && [ ! -n "$isrange" ];then
        echo "commit or range not set"
        exit 1
    fi
    if [ -n "$change_author_date" ];then
        author_date_cmd='&& export GIT_AUTHOR_DATE="'$date'"'
    fi
    if [ -n "$change_committer_date" ];then
        committer_date_cmd='&& export GIT_COMMITTER_DATE="'$date'"'
    fi
fi

cmd='git filter-branch -f --env-filter '\'${test_cmd}' '${author_date_cmd}' '${committer_date_cmd}' '${fix_committer_date_cmd}' || export GIT_COMMITTER_DATE=$GIT_COMMITTER_DATE'\'${range}

[ -n "$debug" ] && echo $cmd

[ -z "$debug" ] && eval $cmd
