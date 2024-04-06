#!/bin/bash


### GLOBAL VARIABLES ###
# invidious instance
invidious=https://yt.artemislena.eu
# temporary files path
tmp='/tmp/yt-download'

HELP_MSG=$(cat << EOM
Usage: yap [OPTIONS] [LINK/SONG_NAME]

Download audio from YouTube using Invidious.

Options:
  -l, --link=LINK         Provide any link pointing to a YouTube video for download.
  -s, --song=SONG_NAME    Search and download by specifying the song name.
  -a, --album=ALBUM       Specify the album name (optional for search).
  -p, --artist=ARTIST     Specify the artist name (optional for search).
  -o, --output=OUTPUT_DIR Specify the output directory (default: 'finish').
  -i, --itag=ITAG         Specify the ITAG for audio quality (default: 139).
  -c, --cover             Include cover image in the downloaded audio file.
  -t, --tag               Include metadata tags in the downloaded audio file.
  -r, --replace           Replace existing files if they have the same name.
  -h, --help              Show this help message.
  
Examples:
  yap https://www.youtube.com/watch?v=VIDEO_ID
  yap --song="Song Name" --artist="Artist Name" --album="Album Name"
  yap -s "Song Name" -p "Artist Name"
  yap -l "https://www.youtube.com/watch?v=VIDEO_ID" -o "custom_output"
EOM
)

# Download .m4a of specified video
audio_download_invidious(){
    name=$1
    id=$2
    itag=$3
    thumbnail=$4 
    output=$5
    echo "Curling $name from: $invidious/latest_version?id=$id&itag=$itag"
    curl -Ls "$invidious/latest_version?id=$id&itag=$itag" -o "$tmp/$name.m4a"
    RC=$(echo $?)
    if [ $RC -ne 0 ]; then
        echo "Could not curl audio!"
        return 1
    fi

    # get cover image
    if [[ "$thumbnail" == "true" ]]; then
        [ $RC -eq 0 ] && curl -Ls "$invidious/vi/$id/maxres.jpg" -o "$tmp/$name-cover.jpg"
        RC=$(echo $?)
        if [ $RC -ne 0 ]; then
            echo "Could not curl thumbnail!"
        fi

        # insert image to audio
        [ $RC -eq 0 ] && (ffmpeg -nostdin -i "$tmp/$name.m4a" -i "$tmp/$name-cover.jpg" -map 0:0 -map 1:0 -acodec copy -id3v2_version 3 "finish/$name.m4a") 2> /dev/null
        if [ $RC -ne 0 ]; then
            echo "Could add thumbnail to audio!"
            cp "$tmp/$name.m4a" "$output/$name.m4a"
        fi
    else
        cp "$tmp/$name.m4a" "$output/$name.m4a"
    fi
    
}


# Function to remove quotes and concatenate strings with '+'
concatenate_with_plus() {
    input="$1"
    # Remove single and double quotes, then replace spaces with '+'
    result=$(echo "$input" | awk -v RS="[\"']" '{gsub(/ /, "+", $0); printf "%s", $0}')
    echo "$result"
}

# Function to remove quotes and concatenate strings with '_'
concatenate_with_underscore() {
    input="$1"
    # Remove single and double quotes, then replace spaces with '+'
    result=$(echo "$input" | awk -v RS="[\"']" '{gsub(/ /, "_", $0); printf "%s", $0}')
    echo "$result"
}


# Get the ID of the first search result on Invidious
get_invidious_audio_search_id(){
    search="$1"
    result=$(wget -nv -qO - "$invidious/search?q=$search+Audio" | grep "watch?v=" | head -n1 | sed -n 's/.*[?&]v=\([^"]*\).*/\1/p')
    echo $result
}

# Get ID out of given link
get_link_audio_id(){
    link=$1
    # forward link to ensure parameter is in link (also work with bit.ly links)
    if [[ $link != *"watch?v="* ]]; then
        link=$(echo $(curl -Ls -o /dev/null -w %{url_effective} $link))
    fi

    # extract video id from link
    id=$(echo $link | sed -n 's/.*[?&]v=\([^&]*\).*/\1/p')

    # Vanced only uses 11 characters for their ids
    id=${id:0:11}
    echo $id
}

is_valid_url(){
    regex='(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'
    if [[ $1 =~ $regex ]]
    then 
        echo "1"
    else
        echo "0"
    fi
}

yap(){
    
    LONGOPTS="itag:,cover,link:,song:,album:,artist:,tag,output:,replace,help"
    OPTIONS="i:,c,l:,s:,a:,p:,t,o:,r,h"

    ! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        # e.g. return value is 1
        #  then getopt has complained about wrong arguments to stdout
        echo "$HELP_MSG"
        return 2
    fi
    # read getopt’s output
    eval set -- "$PARSED"

    # itag for lowest quality m4a (see https://gist.github.com/sidneys/7095afe4da4ae58694d128b1034e01e2)
    itag=139
    thumbImage=false
    tag=false
    replace=false
    link=''
    song=''
    album=''
    artist=''
    output='finish'

    while true; do
        case "$1" in
            -c|--cover)
                thumbImage=true
                shift
                ;;
            -h|--help)
                echo "$HELP_MSG"
                return 0
                ;;
            -i|--itag)
                itag="$2"
                shift 2
                ;;
            -l|--link)
                link="$2"
                shift 2
                ;;
            -s|--song)
                song="$2"
                shift 2
                ;;
            -a|--album)
                album="$2"
                shift 2
                ;;
            -p|--artist)
                artist="$2"
                shift 2
                ;;
            -o|--output)
                output="$2"
                mkdir "$output"
                shift 2
                ;;
            -t|--tag)
                tag=true
                shift
                ;;
            -r|--replace)
                replace=true
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Programming error"
                return 3
                ;;
        esac
    done

    mkdir -p "$tmp" finish

    if [[ $# -ne 1 && "$link" == '' && "$song" == '' ]]; then
        echo "yap: You need to specify at least a link or a song name!"
        return 4
    fi
    positional=$1

    if [[ $(is_valid_url "$positional") == "1" ]]; then
        link="$positional"
    fi

    if [[ "$link" != '' ]]; then
        id=$(get_link_audio_id $link)
    else
        song=$positional
        search=$positional
        if [[ "$artist" != '' ]]; then
            search="$search $artist"
        fi
        if [[ "$album" != '' ]]; then
            search="$search $album"
        fi
        echo "Searching by: $search"
        search=$(concatenate_with_plus "$search")
        id=$(get_invidious_audio_search_id "$search")
    fi

    
    name="$song"

    # If name is not given, take title of the video
    [ "$name" == '' ] && name=$(curl -Ls "$invidious/watch?v=$id" | grep '"title":' | cut -d ':' -f 2- | tr -d [:punct:] | xargs)

    # Skip loop element, when file already exists
    if [[ -f "$output/$name".m4a && "$replace" == "false" ]]; then
        echo -e "Skipping \"$name\", because it already exists" && return 0
    fi

    audio_download_invidious "$name" "$id" "$itag" "$thumbImage" "$output"

    [ -f "$tmp" ] && rmdir "$tmp"
}

