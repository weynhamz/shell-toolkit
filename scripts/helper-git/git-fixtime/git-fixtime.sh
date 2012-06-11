#!/bin/sh
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#

while getopts :acd:firt opt
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
    'i')    increase="TRUE"
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
    if [ -n "$date" ];then
        timestamp=$(date --date="$date" +%s)
    fi
    if [ -n "$isrange" ];then
        set -- $(git rev-list --reverse $1)
    fi
    first=1
    test_cmd='{ '
    while [ -n "$1" ];do
        commit=$(git rev-parse $1)
        [ $first -eq 0 ] && test_cmd=$test_cmd' || '
        test_cmd=$test_cmd'{ '
        test_cmd=$test_cmd'test $GIT_COMMIT = "'$commit'"'
        if [ -n "$date" ];then
            if [ -n "$increase" ];then
                timestamp=$(($timestamp + $RANDOM%180 + 10))
            fi
            date=$(LC_ALL=C date -R --date="@$timestamp")
            if [ -n "$change_author_date" ];then
                test_cmd=$test_cmd' &&  export GIT_AUTHOR_DATE="'$date'"'
            fi
            if [ -n "$change_committer_date" ];then
                test_cmd=$test_cmd' &&  export GIT_COMMITTER_DATE="'$date'"'
            fi
        fi
        test_cmd=$test_cmd'; }'
        first=0
        shift
    done
    test_cmd=$test_cmd'; }'
fi

if [ -n "$date" ];then
    if [ -z "$commit" ] && [ ! -n "$isrange" ];then
        echo "commit or range not set"
        exit 1
    fi
    if [ ! -n "$change_author_date" ] && [ ! -n "$change_committer_date" ];then
        echo "one of -a or -c flag must be set"
        exit 1
    fi
fi

cmd='git filter-branch -f --env-filter '\'${test_cmd}' '${fix_committer_date_cmd}' || export GIT_COMMITTER_DATE=$GIT_COMMITTER_DATE'\'${range}

[ -n "$debug" ] && echo $cmd

[ -z "$debug" ] && eval $cmd
