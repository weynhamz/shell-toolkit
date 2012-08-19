#/bin/bash

LC_ALL=C

dest=$1

workspace=`mktemp -d`

rm -rf $dest.new && cp -rf $dest $dest.new

for file in `find $dest -type f`
do
    # Only match date here, ignore time
    date=`stat $file | grep "Modify:" | cut -n -d: -f2- | sed 's/[0-9]\{2\}\(\.[0-9]\{9\} +[0-9]\{4\}\)/00\1/g'`
    file=${file#$dest/}
    [ -f $dest.new/.gitignore ] && grep -q $file $dest.new/.gitignore || echo $file >> $workspace/files.`date -d "$date" '+%s'`
done

for file in `find $dest`
do
    date=`stat $file | grep "Modify:" | cut -n -d: -f2-`
    touch -m -d "$date" "$dest.new${file#$dest}"
done

cd $dest.new

if ! $(git ls-files | grep -q $file); then
    git init
fi

for file in `ls -1 $workspace/files.* | sort`
do
    date=${file#$workspace/files.}
    git add `cat $file`
    git commit -m "`date -R --date="@$date"`" 2>&1 1>/dev/null
done

git log --pretty=oneline > $workspace/gitlog

git filter-branch -f --env-filter 'export GIT_AUTHOR_DATE=`grep $GIT_COMMIT '$workspace'/gitlog | cut -d" " -f2-` && export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE || cat' -- --all
