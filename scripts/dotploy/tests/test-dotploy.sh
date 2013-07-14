#!/bin/bash

# Function: _abspath
#
#    Get the absolute path for a file
#
#    From: http://stackoverflow.com/questions/59895
#
_abspath() {
    local path=${1:-$(caller | cut -d' ' -f2)}
    local path_dir=$( dirname "$path" )
    while [ -h "$path" ]
    do
        path=$(readlink "$path")
        [[ $path != /* ]] && path=$path_dir/$path
        path_dir=$( cd -P "$( dirname "$path"  )" && pwd )
    done
    path_dir=$( cd -P "$( dirname "$path" )" && pwd )
    echo "$path_dir"
}

ABSPATH=$(_abspath)

if [[ -f $ABSPATH/../../../libs/bashTest/src/bashTest ]]
then
    source "$ABSPATH/../../../libs/bashTest/src/bashTest"
elif [[ -f $ABSPATH/../bundles/bashTest/src/bashTest ]]
then
    source "$ABSPATH/../bundles/bashTest/src/bashTest"
elif [[ -f /usr/share/dotploy/bundles/bashTest/bashTest ]]
then
    source "/usr/share/dotploy/bundles/bashTest/bashTest"
elif [[ -f /usr/share/lib/bashTest/bashTest ]]
then
    source "/usr/share/lib/bashTest/bashTest"
else
    echo "Can not find bashTest, you need to install it as bundles first."
    exit 1
fi

###############################################################################
#
# Test Helpers
#
###############################################################################

ABSPATH=$(_abspath)

_set_up() {
    export PATH=$(realpath $ABSPATH/..):$PATH

    export TEST_FIELD=$ABSPATH'/test-field'

    mkdir -p "$TEST_FIELD/dotsdest"
    mkdir -p "$TEST_FIELD/dotsrepo"
    mkdir -p "$TEST_FIELD/dotsrepo/__DOTDIR"

    cd "$TEST_FIELD"
}

_tear_down() {
    rm -r "dotsdest"
    rm -r "dotsrepo"

    cd "$ABSPATH"

    rmdir -p --ignore-fail-on-non-empty "$TEST_FIELD"
}

_make_layer() {
    local layer
    for layer in "$@";do
        mkdir -p "$(_dirname "$layer")" && touch "$layer"
    done
}

###############################################################################
#
# Actual Tests
#
###############################################################################

USER=$(id -nu)
HOST=$HOSTNAME

_test_run "Shared dot files deployment" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "dotsrepo/__DOTDIR/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "dotsrepo/__DOTDIR/.dotfile"
'

_test_run "User based dot files deployment" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "dotsrepo/__DOTDIR/__USER.$USER/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
'

_test_run "Host based dot files deployment" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
'

_test_run "Host based dot files deployment with user based exits" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
'

_test_run "Host then user based dot file deployment" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
'

_test_run "Fallback host based to shared" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    rm "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "dotsrepo/__DOTDIR/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "dotsrepo/__DOTDIR//.dotfile"
'

_test_run "Fallback user based to shared" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    rm "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "dotsrepo/__DOTDIR/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "dotsrepo/__DOTDIR/.dotfile"
'

_test_run "Fallback host and user based to shared" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir/"
        "dotsrepo/__DOTDIR/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    rm "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "dotsrepo/__DOTDIR/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "dotsrepo/__DOTDIR/.dotfile"
'

_test_run "Fallback host and user based deployment to user based" '
    repo_layer=(
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    rm "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "dotsrepo/__DOTDIR/__USER.$USER/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
'

_test_run "Fallback host and user based deployment to host based" '
    repo_layer=(
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    rm "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
'

_test_run "Fallback host and user based deployment to host based when __USER and __HOST both their" '
    repo_layer=(
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" dotsdest
    rm "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile"
    rmdir "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_symlink "dotsdest/.dotdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir"
    _test_expect_symlink "dotsdest/.dotfile" "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile"
'

_test_run "Backup if destination already exists" '
    repo_layer=(
        "dotsdest/.dotdir1/"
        "dotsdest/.dotfile1"
        "dotsrepo/__DOTDIR/.dotdir1/"
        "dotsrepo/__DOTDIR/.dotfile1"
        "dotsdest/.dotdir2/"
        "dotsdest/.dotfile2"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile2"
        "dotsdest/.dotdir3/"
        "dotsdest/.dotfile3"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile3"
        "dotsdest/.dotdir4/"
        "dotsdest/.dotfile4"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile4"
    )
    _make_layer "${repo_layer[@]}"
    _test_expect_missing "dotsdest/.dotploy/backup"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_directory "dotsdest/.dotploy/backup"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotdir1"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotfile1"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotdir2"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotfile2"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotdir3"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotfile3"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotdir4"
    _test_expect_expr_true "ls -RA dotsdest/.dotploy/backup | grep -q .dotfile4"
'

_test_run "Whether __IGNORE works as expected" '
    repo_layer=(
        "dotsrepo/__DOTDIR/__IGNORE"
        "dotsrepo/__DOTDIR/dir1/"
        "dotsrepo/__DOTDIR/file1"
        "dotsrepo/__DOTDIR/.dotdir1/"
        "dotsrepo/__DOTDIR/.dotfile1"
        "dotsrepo/__DOTDIR/__USER.$USER/__IGNORE"
        "dotsrepo/__DOTDIR/__USER.$USER/dir2/"
        "dotsrepo/__DOTDIR/__USER.$USER/file2"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotfile2"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/dir3/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/file3"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile3"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/dir4/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/file4"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile4"
    )
    _make_layer "${repo_layer[@]}"
    echo "^dir1$"  >> "dotsrepo/__DOTDIR/__IGNORE"
    echo "^file1$" >> "dotsrepo/__DOTDIR/__IGNORE"
    echo "^dir2$"  >> "dotsrepo/__DOTDIR/__USER.$USER/__IGNORE"
    echo "^file2$" >> "dotsrepo/__DOTDIR/__USER.$USER/__IGNORE"
    echo "^dir3$"  >> "dotsrepo/__DOTDIR/__HOST.$HOST/__IGNORE"
    echo "^file3$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/__IGNORE"
    echo "^dir4$"  >> "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/__IGNORE"
    echo "^file4$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/__IGNORE"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_missing "dotsdest/dir1"
    _test_expect_missing "dotsdest/file1"
    _test_expect_missing "dotsdest/dir2"
    _test_expect_missing "dotsdest/file2"
    _test_expect_missing "dotsdest/dir3"
    _test_expect_missing "dotsdest/file3"
    _test_expect_missing "dotsdest/dir4"
    _test_expect_missing "dotsdest/file4"
    _test_expect_symlink "dotsdest/.dotdir1"  "dotsrepo/__DOTDIR/.dotdir1"
    _test_expect_symlink "dotsdest/.dotfile1" "dotsrepo/__DOTDIR/.dotfile1"
    _test_expect_symlink "dotsdest/.dotdir2"  "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/"
    _test_expect_symlink "dotsdest/.dotfile2" "dotsrepo/__DOTDIR/__USER.$USER/.dotfile2"
    _test_expect_symlink "dotsdest/.dotdir3"  "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/"
    _test_expect_symlink "dotsdest/.dotfile3" "dotsrepo/__DOTDIR/__HOST.$HOST/.dotfile3"
    _test_expect_symlink "dotsdest/.dotdir4"  "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/"
    _test_expect_symlink "dotsdest/.dotfile4" "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotfile4"
'

_test_run "Directory contains __KEEPED deployment" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir1/__KEEPED"
        "dotsrepo/__DOTDIR/.dotdir1/subdir/"
        "dotsrepo/__DOTDIR/.dotdir1/subfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_directory "dotsdest/.dotdir1"
    _test_expect_directory "dotsdest/.dotdir2"
    _test_expect_directory "dotsdest/.dotdir3"
    _test_expect_directory "dotsdest/.dotdir4"
    _test_expect_symlink "dotsdest/.dotdir1/subdir"  "dotsrepo/__DOTDIR/.dotdir1/subdir"
    _test_expect_symlink "dotsdest/.dotdir1/subfile" "dotsrepo/__DOTDIR/.dotdir1/subfile"
    _test_expect_symlink "dotsdest/.dotdir2/subdir"  "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir"
    _test_expect_symlink "dotsdest/.dotdir2/subfile" "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
    _test_expect_symlink "dotsdest/.dotdir3/subdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir"
    _test_expect_symlink "dotsdest/.dotdir3/subfile" "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
    _test_expect_symlink "dotsdest/.dotdir4/subdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir"
    _test_expect_symlink "dotsdest/.dotdir4/subfile" "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
'

_test_run "Destination of the directory conatains __KEEPED exists as a file" '
    repo_layer=(
        "dotsdest/.dotdir1"
        "dotsdest/.dotdir2"
        "dotsdest/.dotdir3"
        "dotsdest/.dotdir4"
        "dotsrepo/__DOTDIR/.dotdir1/__KEEPED"
        "dotsrepo/__DOTDIR/.dotdir1/subdir/"
        "dotsrepo/__DOTDIR/.dotdir1/subfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_directory "dotsdest/.dotdir1"
    _test_expect_directory "dotsdest/.dotdir2"
    _test_expect_directory "dotsdest/.dotdir3"
    _test_expect_directory "dotsdest/.dotdir4"
    _test_expect_symlink "dotsdest/.dotdir1/subdir"  "dotsrepo/__DOTDIR/.dotdir1/subdir"
    _test_expect_symlink "dotsdest/.dotdir1/subfile" "dotsrepo/__DOTDIR/.dotdir1/subfile"
    _test_expect_symlink "dotsdest/.dotdir2/subdir"  "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir"
    _test_expect_symlink "dotsdest/.dotdir2/subfile" "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
    _test_expect_symlink "dotsdest/.dotdir3/subdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir"
    _test_expect_symlink "dotsdest/.dotdir3/subfile" "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
    _test_expect_symlink "dotsdest/.dotdir4/subdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir"
    _test_expect_symlink "dotsdest/.dotdir4/subfile" "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
'

_test_run "Destination of the directory conatains __KEEPED exists as a directory" '
    repo_layer=(
        "dotsdest/.dotdir1/"
        "dotsdest/.dotdir2/"
        "dotsdest/.dotdir3/"
        "dotsdest/.dotdir4/"
        "dotsrepo/__DOTDIR/.dotdir1/__KEEPED"
        "dotsrepo/__DOTDIR/.dotdir1/subdir/"
        "dotsrepo/__DOTDIR/.dotdir1/subfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
    )
    _make_layer "${repo_layer[@]}"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_directory "dotsdest/.dotdir1"
    _test_expect_directory "dotsdest/.dotdir2"
    _test_expect_directory "dotsdest/.dotdir3"
    _test_expect_directory "dotsdest/.dotdir4"
    _test_expect_symlink "dotsdest/.dotdir1/subdir"  "dotsrepo/__DOTDIR/.dotdir1/subdir"
    _test_expect_symlink "dotsdest/.dotdir1/subfile" "dotsrepo/__DOTDIR/.dotdir1/subfile"
    _test_expect_symlink "dotsdest/.dotdir2/subdir"  "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir"
    _test_expect_symlink "dotsdest/.dotdir2/subfile" "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
    _test_expect_symlink "dotsdest/.dotdir3/subdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir"
    _test_expect_symlink "dotsdest/.dotdir3/subfile" "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
    _test_expect_symlink "dotsdest/.dotdir4/subdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir"
    _test_expect_symlink "dotsdest/.dotdir4/subfile" "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
'

_test_run "Whether __IGNORE and __KEEPED works together" '
    repo_layer=(
        "dotsrepo/__DOTDIR/.dotdir1/__IGNORE"
        "dotsrepo/__DOTDIR/.dotdir1/__KEEPED"
        "dotsrepo/__DOTDIR/.dotdir1/dir/"
        "dotsrepo/__DOTDIR/.dotdir1/file"
        "dotsrepo/__DOTDIR/.dotdir1/subdir/"
        "dotsrepo/__DOTDIR/.dotdir1/subfile"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__IGNORE"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/dir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/file"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/dir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/file"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/dir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/file"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
    )
    _make_layer "${repo_layer[@]}"
    echo "^dir$"  >> "dotsrepo/__DOTDIR/.dotdir1/__IGNORE"
    echo "^file$" >> "dotsrepo/__DOTDIR/.dotdir1/__IGNORE"
    echo "^dir$"  >> "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__IGNORE"
    echo "^file$" >> "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__IGNORE"
    echo "^dir$"  >> "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__IGNORE"
    echo "^file$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__IGNORE"
    echo "^dir$"  >> "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__IGNORE"
    echo "^file$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__IGNORE"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_missing "dotsdest/.dotdir1/dir"
    _test_expect_missing "dotsdest/.dotdir1/file"
    _test_expect_missing "dotsdest/.dotdir2/dir"
    _test_expect_missing "dotsdest/.dotdir2/file"
    _test_expect_missing "dotsdest/.dotdir3/dir"
    _test_expect_missing "dotsdest/.dotdir3/file"
    _test_expect_missing "dotsdest/.dotdir4/dir"
    _test_expect_missing "dotsdest/.dotdir4/file"
    _test_expect_symlink "dotsdest/.dotdir1/subdir"  "dotsrepo/__DOTDIR/.dotdir1/subdir"
    _test_expect_symlink "dotsdest/.dotdir1/subfile" "dotsrepo/__DOTDIR/.dotdir1/subfile"
    _test_expect_symlink "dotsdest/.dotdir2/subdir"  "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir"
    _test_expect_symlink "dotsdest/.dotdir2/subfile" "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
    _test_expect_symlink "dotsdest/.dotdir3/subdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir"
    _test_expect_symlink "dotsdest/.dotdir3/subfile" "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
    _test_expect_symlink "dotsdest/.dotdir4/subdir"  "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir"
    _test_expect_symlink "dotsdest/.dotdir4/subfile" "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
'

_test_run "Use __IGNORE ignore directory contains __KEEPED" '
    repo_layer=(
        "dotsrepo/__DOTDIR/__IGNORE"
        "dotsrepo/__DOTDIR/.dotdir1/__KEEPED"
        "dotsrepo/__DOTDIR/.dotdir1/subdir/"
        "dotsrepo/__DOTDIR/.dotdir1/subfile"
        "dotsrepo/__DOTDIR/__USER.$USER/__IGNORE"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/__KEEPED"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subdir/"
        "dotsrepo/__DOTDIR/__USER.$USER/.dotdir2/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/.dotdir3/subfile"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/__IGNORE"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/__KEEPED"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subdir/"
        "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/.dotdir4/subfile"
    )
    _make_layer "${repo_layer[@]}"
    echo "^.dotdir1$" >> "dotsrepo/__DOTDIR/__IGNORE"
    echo "^.dotdir2$" >> "dotsrepo/__DOTDIR/__USER.$USER/__IGNORE"
    echo "^.dotdir3$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/__IGNORE"
    echo "^.dotdir4$" >> "dotsrepo/__DOTDIR/__HOST.$HOST/__USER.$USER/__IGNORE"
    dotploy.sh "dotsrepo" "dotsdest"
    _test_expect_missing "dotsdest/.dotdir1"
    _test_expect_missing "dotsdest/.dotdir2"
    _test_expect_missing "dotsdest/.dotdir3"
    _test_expect_missing "dotsdest/.dotdir4"
'

_test_done
