#!/bin/bash
#
# vim: set tabstop=4 shiftwidth=4 expandtab autoindent:
#
#==============================================================================
#
#         FILE: extclean.sh
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Techlive Zheng <techlivezheng@gmail.com>
#      OPTIONS: see --help
#      COMPANY: ---
#      VERSION: 1.0
#      CREATED: 02.05.2012
#     REVISION: 02.08.2012
#  DESCRIPTION: Move files with a specific extension to a new directory and
#               keeping the structure of the current directory.
# REQUIREMENTS: rar for rar extracting
#               p7zip for zip extracting
#               convmv for change codepage
#
#==============================================================================

#
# Get current directory
#
# From: http://stackoverflow.com/questions/59895
#
_current_path() {
    SOURCE="${BASH_SOURCE[0]}"
    DIR="$( dirname "$SOURCE" )"
    while [ -h "$SOURCE" ]
    do
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
        DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
    done
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    echo $DIR
}

#------------------------------------------------------------------------------
# Source the flags processing library
#------------------------------------------------------------------------------
libpath=`_current_path`'/libs'
. $libpath/shflags

#------------------------------------------------------------------------------
# Flags and usage define section
#------------------------------------------------------------------------------
FLAGS_TEXT=`cat << EOF

Options:
EOF`

FLAGS_HELP=`cat << 'EOF'

Move files with a specific extension to a new directory and keeping the structure of the current directory.

Usage:

  extclean.sh [ (-e|--ext) <file_extension> [-i|--ignore] ] \\
              (-t|--tolower) <source_directory>

  extclean.sh [ (-e|--ext) <file_extension> [-i|--ignore] ] \\
              (-m|--move) (-d|--dest) <destination_directory> [-p|--prune] \\
              [-t|--tolower] <source_directory>

  extclean.sh [ (-e|--ext) <file_extension> [-i|--ignore] ] \\
              (-x|--extract) (-d|--dest) <destination_directory> \\
              [ (-c|--conv) <old_codepage>:<new_codepage> ] \\
              [-t|--tolower] <source_directory>
EOF`

DEFINE_string 'ext' '' 'extension of the file to be moved' 'e'
DEFINE_string 'dest' '' 'destination directory to be moved in' 'd'
DEFINE_string 'conv' '' 'convert codepage of the filenames after extraction' 'c'
DEFINE_boolean 'ignore' false 'ignore the case of extension' 'i'
DEFINE_boolean 'tolower' false 'change extension to lowwer case' 't'
DEFINE_boolean 'extract' false 'extract archive files, requre p7zip for zip support, rar for rar support' 'x'
DEFINE_boolean 'move-file' false 'move matched files to another directory' 'm'
DEFINE_boolean 'prune-empty' true 'prune empty directories in the source directory' 'p'

#------------------------------------------------------------------------------
# Process the flags
#------------------------------------------------------------------------------
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

#=== FUNCTION =================================================================
# NAME: _die
# PARAMETER 1: message to show
# DESCRIPTION: Die and show help.
#==============================================================================
_die() {
    [ $# -gt 0 ] && echo "error: $@" >&2
    flags_help
    exit 1
}

#=== FUNCTION =================================================================
# NAME: _ext2lower
# PARAMETER 1: filename to process
# DESCRIPTION: Change the extension of the filename to lower case.
#==============================================================================
_ext2lower() {
    local file=$1
    local name=`basename $file`
    local ext_ori=${name##*.}
    local ext_new=`tr '[A-Z]' '[a-z]' <<< "$ext_ori"`

    [ "$name" != "$ext_ori" ] && \
    [ "$ext_ori" != "$ext_new" ] && \
    mv -v $file ${file%%$ext_ori}$ext_new
}

[ $# = 0 ] && _die

IFS=$'\n'

__src=${1%/}

[ -n "${FLAGS_ext}" ] && __ext=${FLAGS_ext}

#------------------------------------------------------------------------------
# Command of generating the filelist to be processed
#------------------------------------------------------------------------------
__cmd='find $__src -type f'
if [ -n "$__ext" ];then
    __cmd='find $__src -type f -name "*.$__ext"'
    [ ${FLAGS_ignore} -eq ${FLAGS_TRUE} ] && \
    __cmd='find $__src -type f -iname "*.$__ext"'
fi

for f in `eval $__cmd`;do
    if [ -n "$__ext" ];then
        dir=`dirname $f`
        name=`basename $f`

        #----------------------------------------------------------------------
        # Extract archive files of a specfic type
        #----------------------------------------------------------------------
        if [ ${FLAGS_extract} -eq ${FLAGS_TRUE} ];then
            dest_extract=$__src.$__ext.extract
            [ -n "${FLAGS_dest}" ] && dest_extract=${FLAGS_dest}
            dest=${dest_extract%/}${dir#$__src}/${name%.$__ext}
            mkdir -p $dest
            if [ $__ext = 'rar' ];then
                rar x $f $dest 2>&1
                [ $? -ne 0 ] && printf "\nERROR Extract:$f\n" >&2
            fi
            if [ $__ext = 'zip' ];then
                LANG=C 7z x -o$dest $f 2>&1
                [ $? -ne 0 ] && printf "\nERROR Extract:$f\n" >&2
            fi
        fi

        #----------------------------------------------------------------------
        # Move specfic type of files to a new directory basing on their
        # extensions
        #----------------------------------------------------------------------
        if [ ${FLAGS_move_file} -eq ${FLAGS_TRUE} ];then
            dest_movefile=$__src.$__ext
            [ -n "${FLAGS_dest}" ] && dest_movefile=${FLAGS_dest}
            dest=${dest_movefile%/}${dir#$__src}
            mkdir -p $dest
            mv -v $f $dest
            f=${dest%/}/$name #update the file path
        fi
    fi

    #--------------------------------------------------------------------------
    # Change the extension of the filename to lower case
    #--------------------------------------------------------------------------
    [ ${FLAGS_tolower} -eq ${FLAGS_TRUE} ] && _ext2lower $f


    #--------------------------------------------------------------------------
    # Prune empty directory in which the file belongs
    #--------------------------------------------------------------------------
    [ ${FLAGS_prune_empty} -eq ${FLAGS_TRUE} ] && \
    [ `find $dir -mindepth 1 -maxdepth 1 -type f | wc -l` = "0" ] && \
    rmdir -v $dir
done

#------------------------------------------------------------------------------
# Convert the codepage of the filenames after zip extracting
#------------------------------------------------------------------------------
if [ $__ext == 'zip' ] && [ -n "${FLAGS_conv}" ] && [ ${FLAGS_extract} -eq ${FLAGS_TRUE} ];then
    code_old=${FLAGS_conv%:*}
    code_new=${FLAGS_conv#*:}
    convmv -f $code_old -t $code_new -r --notest $dest_extract
fi
