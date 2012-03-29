#!/bin/bash

function doconvert()
{
    return 0;
    filepath=$(dirname $1)
    filename=$(basename $1 | awk -F. '{print $1}')
    logpath="mymencoder/$filepath"
    mkdir -p $logpath
    echo "Coverting ..."
    mv $1{,_}
    [ $? -eq "0" ] || exit 2
    mencoder "$1_" -ofps 23.976 -ovc lavc -oac pcm -o "$filepath/$filename.avi" 2>&1 | sed 's/\r$//g' | sed 's/\r/\n/g' > "$logpath/$filename.log"
    [ $? -eq "0" ] || exit 1
    grep 'Flushing video frames.' "$logpath/$filename.log"
    [ $? -eq "0" ] || exit 1
    mv "$1_" "$logpath/$filename.avi"
    [ $? -eq "0" ] || exit 2
    echo "Done"
    return 0
}

fileinfos=$(find $1 -type f -print | sed 's/ /\\ /g' | xargs file)

IFS=$'\n'

for fileinfo in $fileinfos; do
    filename=$(echo $fileinfo | awk -F, '{print $1}' | awk -F: '{print $1}')
    fileinfo=$(echo $fileinfo | sed 's/ //g')
    filetype=$(echo $fileinfo | awk -F, '{print $1}' | awk -F: '{print $2}')
    echo "$filename:"
    echo "FileType: ${filetype}"
    case $filetype in
        'RIFF(little-endian)data' )
            mediatype=$(echo $fileinfo | awk -F, '{print $2}')
            case $mediatype in
                'AVI')
                    videofps=$(echo $fileinfo | awk -F, '{print $4}')
                    videosize=$(echo $fileinfo | awk -F, '{print $3}')
                    videotype=$(echo $fileinfo | awk -F, '{print $5}' | awk -F: '{print $2}')
                    audiofreq=$(echo $fileinfo | awk -F, '{print $7}' | awk -F')' '{print $1}')
                    audiotype=$(echo $fileinfo | awk -F, '{print $6}' | awk -F: '{print $2}' | awk -F'(' '{print $1}')
                    audiochannel=$(echo $fileinfo | awk -F, '{print $6}' | awk -F: '{print $2}' | awk -F'(' '{print $2}')
                    echo "VideoFPS:  ${videofps}"
                    echo "VideoSize: ${videosize}"
                    echo "VideoType: ${videotype}"
                    echo "AudioType: ${audiotype}"
                    echo "AudioFreq: ${audiofreq}"
                    echo "AudioChannel: ${audiochannel}"
                    if [ $videofps != '23.98fps' ] || [ $videotype != 'FFMpegMPEG-4' ]; then
                       echo "The video need to be converted,as the fps was not 23.98fps or the type was not the FFMpegMPEG-4."
                       doconvert $filename
                    fi
                ;;
                'WAVEaudio')
                ;;
            esac
        ;;
        'MicrosoftASF' )
            echo "Convert Microsoft ASF media type to AVI format..."
            doconvert $filename
        ;;
        'RealMediafile' )
            echo "Convert Real media type to AVI format..."
            doconvert $filename
        ;;
        'MPEGsequence' )
            echo "Convert MPEG media type to AVI format..."
            doconvert $filename
        ;;
        'Oggdata' )
            echo "Convert OGG media type to AVI format..."
            doconvert $filename
        ;;
        * )
        ;;
    esac
    echo "------------------------------------------------------------------------"
done
