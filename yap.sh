#!/bin/bash


### GLOBAL VARIABLES ###
# invidious instance
invidious=https://yt.artemislena.eu
# temporary files path
tmp='/tmp/yt-download'


# Download .m4a of specified video
audio_download_invidious(){
    name=$1
    id=$2
    itag=$3
    echo "Curling $name from: $invidious/latest_version?id=$id&itag=$itag"
    curl -Ls "$invidious/latest_version?id=$id&itag=$itag" -o "$tmp/$name.m4a"
    RC=$(echo $?)
    if [ $RC -ne 0 ]; then
        echo "Could not curl audio!"
    fi

    # get cover image
    [ $RC -eq 0 ] && curl -Ls "$invidious/vi/$id/maxres.jpg" -o "$tmp/$name-cover.jpg"
    RC=$(echo $?)
    if [ $RC -ne 0 ]; then
        echo "Could not curl thumbnail!"
    fi

    # insert image to audio
    [ $RC -eq 0 ] && (ffmpeg -nostdin -i "$tmp/$name.m4a" -i "$tmp/$name-cover.jpg" -map 0:0 -map 1:0 -acodec copy -id3v2_version 3 "finish/$name.m4a") 2> /dev/null
    if [ $RC -ne 0 ]; then
        echo "Could add thumbnail to audio!"
        cp "$tmp/$name.m4a" "finish/$name.m4a"
    fi

}


# Function to remove quotes and concatenate strings with '+'
concatenate_with_plus() {
    input="$1"
    # Remove single and double quotes, then replace spaces with '+'
    result=$(echo "$input" | awk -v RS="[\"']" '{gsub(/ /, "+", $0); printf "%s", $0}')
    echo "$result"
}

# Get the ID of the first search result on Invidious
get_invidious_audio_search_id(){
    search="$1"
    result=$(wget -nv -qO - "$invidious/search?q=$search+Audio" | grep "watch?v=" | head -n1 | sed -n 's/.*[?&]v=\([^"]*\).*/\1/p')
    echo $result
}

is_valid_url(){
    regex='(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'
    if [[ $string =~ $regex ]]
    then 
        echo "1"
    else
        echo "0"
    fi
}

yap(){
    
    LONGOPTS="itag:,save-images"
    OPTIONS="i:,s"

    ! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        # e.g. return value is 1
        #  then getopt has complained about wrong arguments to stdout
        exit 2
    fi
    # read getopt’s output
    eval set -- "$PARSED"

    # itag for lowest quality m4a (see https://gist.github.com/sidneys/7095afe4da4ae58694d128b1034e01e2)
    itag=139

    saveImages=false

    while true; do
        case "$1" in
            -s|--save-images)
                saveImages=true
                shift
                ;;
            -i|--itag)
                itag="$2"
                shift 2
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

    if [[ $# -ne 1 ]]; then
        echo "yap: A single input file is required."
        return 4
    fi
    list=$1

    while read line;
    do
        link=$(echo $line | awk -F' ' '{print $1}')

        # forward link to ensure parameter is in link (also work with bit.ly links)
        if [[ $link != *"youtube.com"* && $link != *"$invidious"* ]]; then
            link=$(echo $(curl -Ls -o /dev/null -w %{url_effective} $link))
        fi

        # extract video id from link
        id=$(echo $link | sed -n 's/.*[?&]v=\([^&]*\).*/\1/p')


        # Vanced only uses 11 characters for their ids
        id=${id:0:11}


        # Get given Name
        name=$(echo $line | awk -F' ' '{print $2}')

        # If name is not given, take title of the video
        [ "$name" == '' ] && name=$(curl -Ls "$invidious/watch?v=$id" | grep '"title":' | cut -d ':' -f 2- | tr -d [:punct:] | xargs)

        # Skip loop element, when file already exists
        [ -f finish/"$name".m4a ] && echo -e "Skipping \"$name\", because it already exists" && continue

        audio_download_invidious "$name" "$id" "$itag"

    done < $list

    [ -f "$tmp" ] && rmdir "$tmp"
}

