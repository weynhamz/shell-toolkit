#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#
#==============================================================================
#
# FILE: git-fixtime.sh
#
# AUTHOR: Techlive Zheng <techlivezheng@gmail.com>
#
# Fix the timestamp mess caused by the git rebase or other git operations.
# Set the author date and/or committer date of certain commit to specific time.
#
# EXAMPLEA:
#
#   * Change the author date of all the commits to its committer date.
#
#           git-fixtime.sh -f -c
#
#   * Change the committer date of the given commit[s] to its author date.
#
#           git-fixtime.sh -f -c HEAD
#           git-fixtime.sh -f -c a203382
#           git-fixtime.sh -f -c a203382 b73215f
#           git-fixtime.sh -f -c a203382~..b73215f

#   * Change the committer date of all the commits to its author date.
#
#           git-fixtime.sh -f -a
#
#   * Change the committer date of the given commit[s] to its author date.
#
#           git-fixtime.sh -f -a HEAD
#           git-fixtime.sh -f -a a203382
#           git-fixtime.sh -f -a a203382 b73215f
#           git-fixtime.sh -f -a a203382~..b73215f
#
#   * Change the author date of the given commit[s] to a given date.
#
#           git-fixtime.sh -a -t "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#   * Change the committer date of the given commit[s] to a given date.
#
#           git-fixtime.sh -c -t "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#   * Change the author date as well as committer date of the given commit[s]
#     to a given date.
#
#           git-fixtime.sh -a -c -t "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#       Or
#
#           git-fixtime.sh -f -a -t "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#       Or
#
#           git-fixtime.sh -f -c -t "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#   * Generate the time by randomly increasing the given time. The increasing
#     range is 3 minitus, this could be changed by -m flag.
#
#           git-fixtime.sh -f -a -t "Mon, 07 Aug 2006 12:34:56 -0600" -i a203382~..b73215f
#           git-fixtime.sh -f -a -t "Mon, 07 Aug 2006 12:34:56 -0600" -i -m 10 a203382~..b73215f
#
#   * Read commits from a file.
#
#           git-fixtime.sh -f -a -t "Mon, 07 Aug 2006 12:34:56 -0600" -i -s some_file
#
#       Example of some_file:
#
#           a203382
#           b73215f
#
#   * Read commit and time info from a file with each line in a 'commit:time'
#     format.
#
#           git-fixtime.sh -f -a -s some_file
#
#       Example of some_file:
#
#           a203382:Mon, 07 Aug 2006 12:34:56 -0600
#           b73215f:Mon, 07 Aug 2006 12:34:56 -0600
#
#   Use '-d' flag to examing the command before an actural performing.
#
#   This script is just a wrapper to `git-filter-branch` whcih by default
#   filtering all branches. In order to reduce the processing time, a specific
#   commits range could be specified with -r flag, or the branch contains the
#   target commit[s] could be specified with -b flag.
#
#   If commit 'a203382' is in branch 'test', then the following command would
#   be faster than the one without '-b' flag.
#
#       git-fixtime.sh -a -t "Mon, 07 Aug 2006 12:34:56 -0600" -b test a203382

#   If commit 'a203382' is between commit 'ys2t311' and 'ac9d115', then the
#   following command would be much faster.
#
#       git-fixtime.sh -a -t "Mon, 07 Aug 2006 12:34:56 -0600" -r ys2t311..ac9d115 a203382
#
#   If bad things happened, `git reflog` could help to get the last ref back.
#
#   Performing on a temporary branch is a good choice. If everything goes fine,
#   then hard reset the HEAD of the original branch to the temporary one.
#
#==============================================================================

showhelp() {
   cat << EOF

A script designed to simplify the procedure to alter git commit time.

USAGE:

    git-fixtime.sh [ -h ]
    git-fixtime.sh [ -d ] [ -b BRANCH | -r RANGE ] [ -f ] [ ( -a | -c ) -t TIME [ -i [ -m INCREASING_RANGE ] ] ] -s SOURCE_FILE
    git-fixtime.sh [ -d ] [ -b BRANCH | -r RANGE ] [ -f ] [ ( -a | -c ) -t TIME [ -i [ -m INCREASING_RANGE ] ] ] COMMIT1 COMMIT2 ...
    git-fixtime.sh [ -d ] [ -b BRANCH | -r RANGE ] [ -f ] [ ( -a | -c ) -t TIME [ -i [ -m INCREASING_RANGE ] ] ] START_COMMIT..FINISH_COMMIT

OPTIONS:

    Options in '[]' is optional, '( -a | -c )' means either '-a' or '-c' has to be specified.

        -h Show help message.
        -d Debugging, output the command.
        -b The branch to be filtered with.
        -r Commits range to be filtered with. Example: a203382..b73215f
        -t Time string. Example: Mon, 07 Aug 2006 12:34:56 -0600
        -a Change author date to the given date.
        -c Change committer date to the given date.
        -f Fix the other date according to -a or -c.
        -i Generate time by randomly increasing from the given time.
        -m Increasing range of -i flag in mintes, default is 3 minites.
        -s Read commit [and date info] from a file with each line in 'commit[:date]' format.

    For more example, please read the source.

EOF
exit 0
}

while getopts :ab:cdfhim:r:s:t: opt
do
    case $opt in
    'd')    debug="TRUE"
            ;;
    'b')    branch="$OPTARG"
            ;;
    'r')    cmrange="$OPTARG"
            ;;
    't')    time=$(LC_ALL=C date -R --date="$OPTARG")
            [ $? -eq 1 ] && {
                echo "Invalid time string"
                showhelp
                exit 1
            }
            ;;
    'f')    fix_time="TRUE"
            ;;
    'a')    change_atime="TRUE"
            ;;
    'c')    change_ctime="TRUE"
            ;;
    'i')    increase="TRUE"
            ;;
    'm')    [ $OPTARG -gt 0 ] || {
                echo "Invalid random range arg"
                showhelp
                exit 1
            }
            increase_range=$OPTARG
            ;;
    's')    source="$OPTARG"
            ;;
    'h')    showhelp
            ;;
      ?)    echo "Invalid Arguments"
            showhelp
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if [ -n "$branch" ]; then
    range="$branch"
elif [ -n "$cmrange" ]; then
    range="-- $cmrange"
else
    range='-- --all'
fi

if [ -n "$1" ] && [ ! -n "$source" ];then
    if [ ! -n "$time" ] && [ ! -n "$fix_time" ];then
        echo "one of -t or -f flag must be set"
        showhelp
        exit 1
    fi

    if [ $# -eq 1 ] && [ $(git rev-parse $1 | wc -l) -eq 2 ];then
        range="-- $1"
        hashlist=$(git rev-list --reverse $1)
    else
        hashlist=$(echo -e "$(echo "$*" | sed "s/ \{1,\}/\n/g")")
    fi
elif [ -n "$source" ];then
    if [ ! -n "$change_atime" ] && [ ! -n "$change_ctime" ] && \
        [ ! -n "$fix_time" ];then
        echo "one of -a, -c or -f flag must be set"
        showhelp
        exit 1
    fi
elif [ ! -n "$fix_time" ];then
    echo "either -s flag, -f flag or the commit[s] to be changed must be set"
    showhelp
    exit 1
fi

if [ -n "$time" ] || [ -n "$fix_time" ];then
    if [ ! -n "$change_atime" ] && [ ! -n "$change_ctime" ];then
        echo "one of -a or -c flag must be set"
        showhelp
        exit 1
    fi
fi

if [ -n "$source" ] || [ -n "$hashlist" ];then
    if [ -n "$time" ] && [ -n "$increase" ];then
        timestamp=$(date --date="$time" +%s)
    fi

    first=1
    test_cmd='{ '
    while IFS=: read -r commit targetime;do
        if [ ! -n "$targetime" ];then
            targetime="$time"
        fi

        if [ -n "$timestamp" ];then
            [ ! -n "$increase_range" ] && increase_range=3
            timestamp=$(($timestamp + $RANDOM%(60 * $increase_range) + 10))
            targetime=$(LC_ALL=C date -R --date="@$timestamp")
        fi

        commit=$(git rev-parse $commit)

        [ $first -eq 0 ] && test_cmd=$test_cmd' || '

        test_cmd=$test_cmd'{ '
        test_cmd=$test_cmd'test $GIT_COMMIT = "'$commit'"'
        if [ -n "$targetime" ];then
            if [ -n "$change_atime" ];then
                test_cmd=$test_cmd' &&  export GIT_AUTHOR_DATE="'$targetime'"'
            fi
            if [ -n "$change_ctime" ];then
                test_cmd=$test_cmd' &&  export GIT_COMMITTER_DATE="'$targetime'"'
            fi
        fi
        test_cmd=$test_cmd'; }'

        first=0

        shift
    done < <([ -n "$source" ] && [ -f "$source" ] && cat "$source" || echo "$hashlist")
    test_cmd=$test_cmd'; }'
fi

if [ -n "$fix_time" ] && [ -n "$change_atime" ];then
    fix_time_cmd='&& export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE'
elif [ -n "$fix_time" ] && [ -n "$change_ctime" ];then
    fix_time_cmd='&& export GIT_AUTHOR_DATE=$GIT_COMMITTER_DATE'
fi

if [ ! -n "$test_cmd" ] && [ ! -n "$fix_time_cmd" ];then
    echo "no flag and no argument speified"
    showhelp
    exit 1
elif [ ! -n "$test_cmd" ];then
    test_cmd="cat"
fi

cmd='git filter-branch -f --env-filter '\'${test_cmd}' '${fix_time_cmd}' || cat'\'' '${range}

[ -n "$debug" ] && echo $cmd

[ -z "$debug" ] && eval $cmd
