#!/bin/bash

while getopts ":cs" optname
do
	case "$optname" in
		"s")
			SPLIT=1
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

#user.log
#auth.log
#dmesg.log
#pacman.log
LOGS=(
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

mkdir -p $BACKUPDIR
mkdir -p $BACKUPOLDDIR

clean() {
	mkdir $PROCESSDIR/mail
	for i in `ls -1 mail.log.*`;do
		mv *${i#mail.log} $PROCESSDIR/mail
	done

	mkdir $PROCESSDIR/cron
	for i in `ls -1 crond.log.*`;do
		mv *${i#crond.log} $PROCESSDIR/cron
	done

	mkdir $PROCESSDIR/left
	mv *.log.* $PROCESSDIR/left

	mkdir $PROCESSDIR/errors
	mv errors.log.* $PROCESSDIR/errors

	mkdir $PROCESSDIR/messages
	mv messages.log.* $PROCESSDIR/messages
}

split(){
	for i in `cat $1 | cut -d: -f1,2,3 | sed 's/  / /g' | cut -d' ' -f5- | sed 's/\[[[:alnum:]]*\]//g' | sed 's/\[.*\]//g' | sed 's/^ *//g' | sed 's/ *$//g' | sed 's/://g' | sort -u`
	do
		grep -E "($HOSTNAME $i:|$HOSTNAME $i\[[[:alnum:]]*\]:)" $1 > $1.$(echo $i | sed 's:/:_:g')
	done
	sed -i 's/\[[[:alnum:]]*\]//g' *.log.*
}

splitr() {
	next=1
	while [ -f $1.$next ]
	do
		split $1
		next=$(expr $next + 1)
	done

}

combine() {
	start=1
	if [ -f $1.$start ];then
		cp $1.$start $1.$start.tmp
		mv $1.$start $BACKUPOLDDIR

		next=$(expr $start + 1)
		while [ -f $1.$next ]
		do
			cp $1.$next $1.$next.tmp
			mv $1.$next $BACKUPOLDDIR

			cat $1.$start.tmp >> $1.$next.tmp
			rm $1.$start.tmp

			start=$next

			next=$(expr $next + 1)
		done

		mv $1.$start.tmp $1-combined
	fi
}

if [ $SPLIT -eq 1 ];then
	if [ -n "$1" ];then
		split $1
	else
		cd $LOGDIR
		for j in ${LOGS[@]}
		do
			split $j
		done
		clean
	fi
fi

if [ $COMBINE -eq 1 ];then
	if [ -n "$1" ];then
		combine $1
	else
		cd $OLDDIR
		for j in ${LOGS[@]}
		do
			combine $j
		done
	fi
fi
