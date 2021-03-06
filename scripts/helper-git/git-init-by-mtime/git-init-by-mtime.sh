#/bin/bash

LC_ALL=C

if [ -n "$1" ] && [ -d "$1" ]; then
    dest=$1
else
    dest='.'
fi

workspace=`mktemp -d`

#Backup
tar -cf $workspace/backup.tar $dest
echo "Backup $dest to $workspace/backup.tar"

#Get date
for file in `find $dest -type f`
do
    # Only match date here, ignore time
    date=`stat $file | grep "Modify:" | cut -n -d: -f2- | sed 's/[0-9]\{2\}\(\.[0-9]\{9\} +[0-9]\{4\}\)/00\1/g'`
    file=${file#$dest/}
    [ -f $dest/.gitignore ] && grep -q $file $dest/.gitignore || echo $file >> $workspace/files.`date -d "$date" '+%s'`
done

cd $dest

#Check and init repo
if ! $(git ls-files | grep -q $file); then
    git init
fi

#Commit files
for file in `ls -1 $workspace/files.* | sort`
do
    date=${file#$workspace/files.}
    git add `cat $file`
    git commit -m "`date -R --date="@$date"`" 2>&1 1>/dev/null
done

#Fix date
git filter-branch -f --env-filter 'export GIT_AUTHOR_DATE=`git log -1 --pretty=%s $GIT_COMMIT` && export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE || cat' -- --all
