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
#           git-fixtime.sh -a -t "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#   * Change the author date as well as committer date of the given commit[s]
#     to a given date.
#
#           git-fixtime.sh -a -c -t "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#       Equals to
#
#           git-fixtime.sh -f -a -t "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#   * The following will do nothing, it is nouse.
#
#           git-fixtime.sh -c -f -t "Mon, 07 Aug 2006 12:34:56 -0600" a203382
#
#   * Generate the time by randomly increasing the given time. The increasing
#     range is 3 minitus, this could be changed by -m flag.
#
#           git-fixtime.sh -a -f -t "Mon, 07 Aug 2006 12:34:56 -0600" -i -r a203382~..b73215f
#           git-fixtime.sh -a -f -t "Mon, 07 Aug 2006 12:34:56 -0600" -i -m 10 -r a203382~..b73215f
#
#   * Read commit and time info from a file with each line in a 'commit:time'
#     format.
#
#           git-fixtime.sh -a -f -s some_file
#
#       Example of some_file:
#
#           a203382:Mon, 07 Aug 2006 12:34:56 -0600
#           b73215f:Mon, 07 Aug 2006 12:34:56 -0600
#
#   -d flag could be used to examing the command before an actural performing.
#
#   This script is just a wrapper to `git-filter-branch` whcih by default
#   filtering all branches, in order to reduce the processing time, a specific
#   branch which contains the target commit[s] could be specified by flag -b.
#
#   For example, if commit 'a203382' is in branch 'test', then the following
#   command would be faster than the one without '-b' flag.
#
#       git-fixtime.sh -a -t "Mon, 07 Aug 2006 12:34:56 -0600" -b test a203382
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

    git-fixtime.sh [ -d ] [ -f ] [ -b BRANCH ] [ ( -a | -c ) -t TIME [ -i [ -m INCREASING_RANGE ] ] ] COMMIT1 COMMIT2 ...
    git-fixtime.sh [ -d ] [ -f ] [ -b BRANCH ] [ ( -a | -c ) -t TIME [ -i [ -m INCREASING_RANGE ] ] ] -r COMMIT1..COMMIT2
    git-fixtime.sh [ -d ] [ -f ] [ -b BRANCH ] ( -a | -c ) -s SOURCE_FILE
    git-fixtime.sh [ -h ]

OPTIONS:

    Options in '[]' is optional, '( -a | -c )' means either '-a' or '-c' has to be specified.

        -a Change author date to the given date.
        -b The branch to be filtered with.
        -c Change committer date to the given date.
        -t Time format string. Example: Mon, 07 Aug 2006 12:34:56 -0600
        -f Set commiter date same as author date.
        -r The given argument is a commit range. Example: a203382..b73215f
        -d Debug mode, output the command to be executed.
        -i Generate the time by randomly increasing the given time.
        -m Specify the increasing range of -i flag in mintes, default is 3 minites.
        -s Read commit and date info from a file with each line in a 'commit:date' format.
        -h Show help message.

    For more example, please read the source.

EOF
exit 0
}

while getopts :ab:cdfhim:rs:t: opt
do
    case $opt in
    't')    time=$(LC_ALL=C date -R --date="$OPTARG")
            [ $? -eq 1 ] && exit 1
            ;;
    'a')    change_author_date="TRUE"
            ;;
    'b')    branch="$OPTARG"
            ;;
    'c')    change_committer_date="TRUE"
            ;;
    'f')    fix_committer_date_cmd='&& export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE'
            ;;
    'r')    isrange="TRUE"
            ;;
    'd')    debug="TRUE"
            ;;
    'i')    increase="TRUE"
            ;;
    'm')    [ $OPTARG -gt 0 ] || {
                echo "Invalide random range arg"
                exit 1
            }
            random_minite=$OPTARG
            ;;
    's')    source="TRUE"
            source_file=$OPTARG
            ;;
    'h')    showhelp
            ;;
      ?)    echo "Invalid Arg"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if [ -n "$branch" ]; then
    range="$branch"
else
    range='-- --all'
fi

if [ -n "$1" ] && [ ! -n "$source" ];then
    if [ -n "$isrange" ];then
        hashlist=$(git rev-list --reverse $1)
    else
        hashlist=$(echo -e "$(echo "$*" | sed "s/ \{1,\}/\n/g")")
    fi
    if [ -n "$time" ];then
        hashlist=$(echo "$hashlist" | sed "s/$/:$time/g")
    elif [ ! -n "$fix_committer_date_cmd" ];then
        echo "-d flag is required"
        exit 1
    fi
fi

if [ -n "$source" ] || [ -n "$hashlist" ];then
    if [ ! -n "$source" ] && [ -n "$time" ] && [ -n "$increase" ];then
        timestamp=$(date --date="$time" +%s)
    fi

    first=1
    test_cmd='{ '
    while IFS=: read -r commit time;do
        if [ -n "$timestamp" ];then
            [ ! -n "$random_minite" ] && random_minite=3
            timestamp=$(($timestamp + $RANDOM%(60 * $random_minite) + 10))
            time=$(LC_ALL=C date -R --date="@$timestamp")
        fi

        commit=$(git rev-parse $commit)
        [ $first -eq 0 ] && test_cmd=$test_cmd' || '
        test_cmd=$test_cmd'{ '
        test_cmd=$test_cmd'test $GIT_COMMIT = "'$commit'"'
        if [ -n "$time" ];then
            if [ -n "$change_author_date" ];then
                test_cmd=$test_cmd' &&  export GIT_AUTHOR_DATE="'$time'"'
            fi
            if [ -n "$change_committer_date" ];then
                test_cmd=$test_cmd' &&  export GIT_COMMITTER_DATE="'$time'"'
            fi
        fi
        test_cmd=$test_cmd'; }'
        first=0
        shift
    done < <([ -n "$source" ] && [ -f $source_file ] && cat $source_file || echo "$hashlist")
    test_cmd=$test_cmd'; }'
fi

if [ -n "$time" ];then
    if [ -z "$commit" ] && [ ! -n "$isrange" ];then
        echo "commit or range not set"
        exit 1
    fi
    if [ ! -n "$change_author_date" ] && [ ! -n "$change_committer_date" ];then
        echo "one of -a or -c flag must be set"
        exit 1
    fi
fi

if [ ! -n "$test_cmd" ] && [ ! -n "$fix_committer_date_cmd" ];then
    echo "no flag and no argument speified"
    exit 1
elif [ ! -n "$test_cmd" ];then
    test_cmd="cat"
fi

cmd='git filter-branch -f --env-filter '\'${test_cmd}' '${fix_committer_date_cmd}' || cat'\'' '${range}

[ -n "$debug" ] && echo $cmd

[ -z "$debug" ] && eval $cmd
