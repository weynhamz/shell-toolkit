#!/bin/sh
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#
#==============================================================================
#
# FILE: git-fixtime.sh
#
# AUTHOR: Techlive Zheng <techlivezheng@gmail.com>
#
# Fix the time mass caused by the git rebase or other git operations.
# Set the author date and/or committer date of certain commit to specific time.
#
# EXAMPLEA:
#
#   * Change the committer date of all the commits to its author date.
#
#           git-fixtime.sh -f
#
#   * Change the committer date of the given commit[s] to its author date.
#
#           git-fixtime.sh -f HEAD                  # Any valid ref in git
#           git-fixtime.sh -f a203382
#           git-fixtime.sh -f a203382 b73215f
#           git-fixtime.sh -f -r a203382~..b73215f  # All the commits between
#                                                     a203382 and b73215f, the
#                                                     appended ~ of a203382 is
#                                                     necessary.
#
#   * Change the author date of the given commit[s] to a given date.
#
#           git-fixtime.sh -a -d "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#   * Change the author date as well as committer date of the given commit[s]
#     to a given date.
#
#           git-fixtime.sh -a -c -d "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#       Equals to
#
#           git-fixtime.sh -f -a -d "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#   * The following will do nothing, it is nouse.
#
#           git-fixtime.sh -c -f -d "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#   * Generate the date by randomly increasing the given date. The increasing
#     range is 3 minitus.
#
#           git-fixtime.sh -a -f -d "Mon, 07 Aug 2006 12:34:56 -0600" -i -r a203382~..b73215f
#
#   -t flag could be used to examing the command before an actural performing.
#
#   If bad things happened, `git reflog` could help to get the last ref back.
#
#   Performing on a temporary branch is a good choice. If everything goes fine,
#   then hard reset the HEAD of the original branch to the temporary one.
#
#==============================================================================

showhelp() {
   cat << EOF

USAGE:

    git-fixtime.sh [ -t ] [ -h ] [ -f ] [ ( -a | -c ) -d DATE [ -i ] ] COMMIT1 COMMIT2 ...
    git-fixtime.sh [ -t ] [ -h ] [ -f ] [ ( -a | -c ) -d DATE [ -i ] ] -r COMMIT1..COMMIT2

OPTIONS:

        -a Change author date to the given date.
        -c Change committer date to the given date.
        -d RFC 2822 format string. Example: Mon, 07 Aug 2006 12:34:56 -0600
        -f Set commiter date same as author date.
        -r The given argument is a commit range. Example: a203382..b73215f
        -t Debug mode, output the command to be executed.
        -i Generate the date by randomly increasing the given date. The increasing range is 3 minites.
        -h Show help message.

    For more example, please read the source.

EOF
exit 0
}

while getopts :acd:fhirt opt
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
    'h')    showhelp
            ;;
      ?)    echo "Invalid Arg"
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

if [ "$test_cmd" == "cat" ] && [ ! -n "$fix_committer_date_cmd" ];then
    echo "no flag and no argument speified"
    exit 1
fi

cmd='git filter-branch -f --env-filter '\'${test_cmd}' '${fix_committer_date_cmd}' || export GIT_COMMITTER_DATE=$GIT_COMMITTER_DATE'\'${range}

[ -n "$debug" ] && echo $cmd

[ -z "$debug" ] && eval $cmd
