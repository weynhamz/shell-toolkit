#!/bin/bash

while getopts ":csm" optname
do
	case "$optname" in
		"s")
			SPLIT=1
			;;
		"m")
			MERGE=1
			;;
		"c")
			COMBINE=1
			;;
		":")
			echo "No argument value for option $OPTARG"
			;;
		"?")
			echo "Unknown option $OPTARG"
			;;
		*)
			echo "Unknown error while processing options"
			;;
	esac
done

shift $((OPTIND - 1))

LOGS=(
	"user.log"
	"auth.log"
	"mail.log"
	"crond.log"
	"daemon.log"
	"errors.log"
	"kernel.log"
	"syslog.log"
	"messages.log"
	"everything.log"
)

LOGDIR=/var/log
OLDDIR=/var/log/old
BACKUPDIR=/var/log/.backup
PROCESSDIR=/var/log/.process
BACKUPOLDDIR=/var/log/.backup/old

#
# Split log files by the command
#
split(){
	local output=${2:-1}
	for i in `cat $1 | cut -d: -f1,2,3 | sed 's/  / /g' | cut -d' ' -f5- | sed 's/\[[[:alnum:]]*\]//g' | sed 's/\[.*\]//g' | sed 's/^ *//g' | sed 's/ *$//g' | sed 's/://g' | sort -u`
	do
		grep -E "($HOSTNAME $i:|$HOSTNAME $i\[[[:alnum:]]*\]:)" $1 > ${output}.$(echo $i | sed 's:/:_:g')
	done
	sed -i 's/\[[[:alnum:]]*\]//g' *.log.*
}

#
# Recursively split rotated log files
#
splitr() {
	next=1
	while [ -f $1.$next ]
	do
		split $1 $1.next
		next=$(expr $next + 1)
	done

}

#
# Combine rotated log files into one
#
combine() {
	mkdir -p $BACKUPOLDDIR

	prev=1
	if [ -f $1.$prev ];then
		cp $1.$prev $1.$prev.tmp
		mv $1.$prev $BACKUPOLDDIR

		next=$(expr $prev + 1)
		while [ -f $1.$next ]
		do
			cp $1.$next $1.$next.tmp
			mv $1.$next $BACKUPOLDDIR

			cat $1.$prev.tmp >> $1.$next.tmp
			rm $1.$prev.tmp

			prev=$next

			next=$(expr $next + 1)
		done

		mv $1.$prev.tmp $1-combined
	fi
}

#
# Merge the current log file along with
# the rotated files into one
#
mksingle() {
	mkdir -p $BACKUPDIR
	cd $OLDDIR
	for j in ${LOGS[@]}
	do
		combine $j
		cat $LOGDIR/$j >> $j-combined
		mv $LOGDIR/$j $BACKUPDIR/
		mv $j-combined $LOGDIR/$j
		chown root:log $LOGDIR/$j
	done
}

if [[ $SPLIT -eq 1 ]];then
	if [ -n "$1" ];then
		split $1
	else
		cd $LOGDIR
		for j in ${LOGS[@]}
		do
			[ -f $j ] && split $j
		done

		mkdir -p $PROCESSDIR/auth
		mv auth.log.*     $PROCESSDIR/auth

		mkdir -p $PROCESSDIR/user
		mv user.log.*     $PROCESSDIR/user

		mkdir -p $PROCESSDIR/mail
		for i in `ls -1 mail.log.*`;do
			mv *${i#mail.log} $PROCESSDIR/mail
		done

		mkdir -p $PROCESSDIR/cron
		for i in `ls -1 crond.log.*`;do
			mv *${i#crond.log} $PROCESSDIR/cron
		done

		mkdir -p $PROCESSDIR/errors
		mv errors.log.* $PROCESSDIR/errors

		mkdir -p $PROCESSDIR/messages
		mv messages.log.* $PROCESSDIR/messages

		mkdir -p $PROCESSDIR/left
		mv *.log.* $PROCESSDIR/left

		mv $PROCESSDIR/user/user.log.shutdown $PROCESSDIR/left
	fi
fi

if [[ $COMBINE -eq 1 ]];then
	if [ -n "$1" ];then
		combine $1
	else
		cd $OLDDIR
		for j in ${LOGS[@]}
		do
			[ -f $j ] && combine $j
		done
	fi
fi

if [[ $MERGE -eq 1 ]];then
	mksingle
fi
