#!/bin/bash
#
# Filename: epacman.sh
#

export LC_ALL=C

#
# Assign heredoc statement to a variable
#
# See: http://stackoverflow.com/questions/1167746
#
# A space character after a '\' at the end of line is necessary.
#
__help=$(cat << 'EOF'

View system packages information in a pretty style.

Usage:

    epacman.sh [-t] (([-g] [-l]) [-D] [-R]) \ 
               [-h|--help] [-e|--explicit] [-d|--dependency] \ 
               [(-f|--file) (-|<file>)] [-o|--output]

Options:

    -t  Debug mode
    -g  List packages group
    -l  List packages not in any group
    -D  List packages dependency
    -R  List packages requirements
    -h, --help
        Help information
    -e, --explicit
        Show explicitly installed packages
    -d, --dependency
        Show packages intalled as dependency
    -f, --file (-|<file>)
        Read packages information from <file> or stdin(-)
        Packages information be the result generated by
        'pacman -Q' in ASCII.
    -o, --output
        Output packages information to stdout or <file> if '-f' is set.
EOF
)

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

_packages_info() {
    if [ -n "$explicit" ]; then
        packages=$(pacman -Qe)
    elif [ -n "$dependency" ]; then
        packages=$(pacman -Qd)
    else
        packages=$(pacman -Q)
    fi

    echo "$packages" | cut -d' ' -f 1 | xargs pacman -Qi
}

while [ $# -gt 0 ]
do
    case $1 in
        -h | --help)
            echo "$__help"
            exit 0
            ;;
        -f | --file)
            file=$2
            shift
            ;;
        -o | --output)
	        output=TRUE
            ;;
        -t)
            debug=TRUE
            args_awk=$args_awk" $1"
            ;;
        -l)
            args_awk=$args_awk" $1"
            ;;
        -g)
            args_awk=$args_awk" $1"
            ;;
        -D)
            args_awk=$args_awk" $1"
            ;;
        -R)
            args_awk=$args_awk" $1"
            ;;
        -e | --explicit)
            explicit=TRUE
            ;;
        -d | --dependency)
            dependency=TRUE
            ;;
        -*)
            arg=$1
            arg_2=${arg#-?}
            if [ -n "$arg_2" ]; then
                shift
                arg_1=${arg%$arg_2}
                args_new=$arg' '$arg_1' -'$arg_2' '$@
                set -- $args_new
            else
                echo "Invalid Arg"
                echo "$help"
                exit 1
            fi
            ;;
        *)
            break
            ;;
    esac
    shift
done

if [ -n "$output" ]; then
    packagesinfo=$(_packages_info)
    if [ -n "$file" ]; then
        if [ "$file" = "-" ]; then
            echo "$packagesinfo"
        elif [ -w "$file" ]; then
            echo "$packagesinfo" > $file
        elif [ ! -f "$file" ]; then
            touch "$file"
            echo "$packagesinfo" > $file
        else
            echo "Could not write to file '$file'."
            exit 1
        fi
    else
        echo "$packagesinfo"
    fi
    exit 0
else
    if [ -n "$file" ]; then
        if [ "$file" = "-" ]; then
            packagesinfo=$(cat)
        elif [ -f "$file" ]; then
            packagesinfo=$(cat $file)
        else
            echo "File '$file' does not exist."
            exit 1
        fi
    else
        packagesinfo=$(_packages_info)
    fi
fi

set -- $args_awk

echo "$packagesinfo" | $(_current_path)'/awks/epacman.awk' "$@"
