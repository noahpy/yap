#!/bin/sh


### GLOBAL VARIABLES ###
HELP_MSG=$(cat << EOM
Usage: yap [OPTIONS] [LINK/SEARCH_TERM]

Download audio from YouTube using Invidious.

Options:
  -l, --link=LINK         Download from link pointing to a video / playlist.
  -s, --song=SONG_NAME    Search and download by specifying the song name.
  -a, --album=ALBUM       Specify the album name (optional for search).
  -p, --artist=ARTIST     Specify the artist name (optional for search).
  -o, --output=OUTPUT_DIR Specify the output directory (default: 'finish').
  -i, --itag=ITAG         Specify the ITAG for audio quality (default: 139).
  -c, --cover             Include cover image in the downloaded audio file.
  -t, --tag               Include metadata tags in the downloaded audio file.
  -r, --replace           Replace existing files if they have the same name.
      --play=COMMAND      Execute COMMAND AUDIO_FILE after finished download.
  -v, --interactive       Run everything interactively.
  -h, --help              Show this help message.

  
Examples:
  yap "https://www.youtube.com/watch?v=VIDEO_ID"
  yap --song="Song Name" --artist="Artist Name" --album="Album Name"
  yap -s "Song Name" -p "Artist Name"
  yap -l "https://www.youtube.com/watch?v=VIDEO_ID" -o "custom_output"
EOM
)

# Download .m4a of specified video
audio_download_invidious(){
    local name=$1
    local id=$2
    local itag=$3
    local thumbnail=$4 
    local output=$5
    local tag=$6
    echo "Curling $name from: $invidious/latest_version?id=$id&itag=$itag"
    curl -Ls "$invidious/latest_version?id=$id&itag=$itag" -o "$tmp/$name.m4a"
    RC=$(echo $?)
    if [ $RC -ne 0 ]; then
        echo "Could not curl audio!"
        return 1
    fi

    if [[ "$thumbnail" == "true" || "$tag" == "true" ]]; then
        # get cover image
        curl -Ls "$invidious/vi/$id/maxres.jpg" -o "$tmp/$name-cover.jpg"
        RC=$(echo $?)
        if [ $RC -ne 0 ]; then
            echo "Could not curl thumbnail!"
        fi

        if [[ "$thumbnail" == "true" ]]; then
            # insert image to audio
            [ $RC -eq 0 ] && (ffmpeg -nostdin -i "$tmp/$name.m4a" -i "$tmp/$name-cover.jpg" -map 0:0 -map 1:0 -acodec copy -id3v2_version 3 "finish/$name.m4a") 2> /dev/null
            RC=$(echo $?)
            if [[ $RC -ne 0 ]]; then
                echo "Could not add thumbnail to audio!"
                mv "$tmp/$name.m4a" "$output/$name.m4a"
            fi
            return 0
        fi
    fi

    mv "$tmp/$name.m4a" "$output/$name.m4a"
    
}

# Function to find the longest common substring
find_longest_common_substring() {
    if ((${#1}>${#2})); then
       long=$1 short=$2
    else
       long=$2 short=$1
    fi

    local lshort=${#short}
    local score=0
    for ((i=0;i<lshort-score;++i)); do
       for ((l=score+1;l<=lshort-i;++l)); do
          sub=${short:i:l}
          [[ $long != *$sub* ]] && break
          subfound=$sub score=$l
       done
    done

    if ((score)); then
       echo "$subfound"
    fi
}

# clean title name
clean_title_name(){
    TITLE_WORDS=("official" "video" "audio" "lyric" "lyrics" "offizielles" "musikvideo" "mv" "nbsp" "topic" "soundtrack" "sound" "$2")
    local str="$1"
    str=$(echo "$str" | sed -E 's/\([^)]+\)//g')
    for word in "${TITLE_WORDS[@]}"; do
        str=$(echo "$str" | sed -E "s/\b${word}\b//gi")
    done
    str=$(echo "$str" | tr -d '[:punct:]')       # Remove all punctuation characters
    str=$(echo "$str" | sed -E 's/ +/ /g')           # Reduce consecutive whitespaces to one
    str=$(echo "$str" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//') # Trim whitespaces

    echo "$str"
}

# clean playlist name
clean_playlist_name(){
    TITLE_WORDS=("official" "video" "audio" "lyric" "lyrics" "offizielles" "musikvideo" "mv" "nbsp" "Topic" "playlist" "album" "invidious" "$2")
    local str="$1"
    str=$(echo "$str" | sed -E 's/\([^)]+\)//g')
    for word in "${TITLE_WORDS[@]}"; do
        str=$(echo "$str" | sed -E "s/\b${word}\b//gi")
    done
    str=$(echo "$str" | tr -d '[:punct:]')       # Remove all punctuation characters
    str=$(echo "$str" | sed -E 's/ +/ /g')           # Reduce consecutive whitespaces to one
    str=$(echo "$str" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//') # Trim whitespaces

    echo "$str"
}



# Function to remove quotes and concatenate strings with '+'
concatenate_with_plus() {
    local input="$1"
    # Remove single and double quotes, then replace spaces with '+'
    local result=$(echo "$input" | awk -v RS="[\"']" '{gsub(/ /, "+", $0); printf "%s", $0}')
    echo "$result"
}

# Function to remove quotes and concatenate strings with '_'
concatenate_with_underscore() {
    local input="$1"
    # Remove single and double quotes, then replace spaces with '+'
    local result=$(echo "$input" | awk -v RS="[\"']" '{gsub(/ /, "_", $0); printf "%s", $0}')
    echo "$result"
}


# Get the ID of the first search result on Invidious
get_invidious_audio_search_id(){
    local search="$1"
    local result=$(wget -nv -qO - "$invidious/search?q=$search+Audio" | grep "watch?v=" | head -n1 | sed -n 's/.*[?&]v=\([^"]*\).*/\1/p')
    echo $result
}

# Get ID out of given link
get_link_audio_id(){
    local link=$1
    
    # extract video id from link
    local id=$(echo $link | sed -n 's/.*[?&]v=\([^&]*\).*/\1/p')

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

    # invidious instance
    local invidious=https://yt.artemislena.eu
    # temporary files path
    local tmp='/tmp/yt-download'

    
    LONGOPTS="itag:,cover,link:,song:,album:,artist:,tag,output:,replace,help,play:,interactive"
    OPTIONS="i:,c,l:,s:,a:,p:,t,o:,r,h,v"

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
    local itag=139
    local thumbImage=false
    local tag=false
    local replace=false
    local interactive=false
    local link=''
    local song=''
    local album=''
    local artist=''
    local output='finish'
    local play=''


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
            -v|--interactive)
                interactive=true
                shift
                ;;
            --play)
                play="$2"
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

    mkdir -p "$tmp" "$output"

    if [[ $# -gt 1 ]];then
        echo "Found more than one positional argument:$1 and $2"
        return 4
    fi

    if [[ $# -ne 1 && "$link" == '' && "$song" == '' ]]; then
        echo "yap: You need to specify at least a link, search term or a song name!"
        return 4
    fi
    local positional=$1


    if [[ $(is_valid_url "$positional") == "1" ]]; then
        link="$positional"
    fi

    # get id from link
    if [[ "$link" != '' ]]; then
        # forward link to ensure parameter is in link (also work with bit.ly links)
        if [[ $link != *"watch?v="* ]]; then
            link=$(echo $(curl -Ls -o /dev/null -w %{url_effective} $link))
        fi
        if [[ $link == *"list="* ]]; then
            echo "Detected playlist!"
            local id=$(echo "$link" | sed -n 's/.*[?&]list=\([^"]*\).*/\1/p')
            [ "$artist" == '' ] && artist="-"
            [ "$album" == '' ] && album="-"
            yap_playlist "$id" "$artist" "$album" "$thumbImage" "$replace" "$tag" "$output" "$interactive" "$play"
            return 0
        fi

        id=$(get_link_audio_id $link)
    # get id from search
    else
        local search="$song"
        [ "$positional" != '' ] && search=$positional
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

    
    local name="$song"

    local site_info=$(curl -Ls "$invidious/watch?v=$id")
    
    # echo "$site_info" | less

    local title=$(echo "$site_info" | grep '"title":' | cut -d ':' -f 2- | tr -d [:punct:] | xargs) 
    echo "Found video: $title"
    [ "$name" == '' ] && name="$title"

    # If artis not specified, derive from site info
    if [[ "$artist" == '' ]]; then
        local channel=$(echo "$site_info" | grep '"channel-name"' | cut -d '>' -f 2 | cut -d '<' -f 1)
        artist=$(find_longest_common_substring "$channel" "$name")
        [ ${#artist} -le 4 ] && artist=$(clean_title_name "$channel")
        echo "Derived artist name: $artist"

        if [[ "$interactive" == "true" ]]; then
            read -p "Enter alternative (empty for default): " answer
            [ "$answer" != '' ] && artist="$answer"
        fi
    fi


    # Derive song name if not specified
    if [[ "$song" == '' ]]; then
        name=$(clean_title_name "$name" "$artist") 
        echo "Derived song name: $name"
        if [[ "$interactive" == "true" ]]; then
            read -p "Enter alternative (empty for default): " answer
            [ "$answer" != '' ] && name="$answer"

        fi
    fi

   local file_name=$(concatenate_with_underscore "$name")
    # Skip loop element, when file already exists
    if [[ -f "$output/$file_name".m4a && "$replace" == "false" ]]; then
        echo -e "Skipping \"$name\", because it already exists"
    else
        audio_download_invidious "$file_name" "$id" "$itag" "$thumbImage" "$output" "$tag"
    fi

    if [[ "$tag" == "true" ]]; then
        # set tags
        tageditor set title="$name" artist="$artist" album="$album" cover="$tmp/$file_name-cover.jpg" -f "$output/$file_name.m4a" > /dev/null
        RC=$(echo $?)
        if [ $RC -ne 0 ]; then
            echo -e "Something went wrong when tagging!"
        fi
        rm "$output/$file_name.m4a.bak"
    fi

    [ -f "$tmp" ] && rmdir "$tmp"

    if [[ "$play" != '' ]]; then
        echo -e "\nExecuting $play"
        $play "$output/$file_name.m4a"
    fi
}

yap_playlist(){
    local id=$1
    local artist=$2
    local album=$3
    local thumbImage=$4
    local replace=$5
    local tag=$6
    local output=$7
    local interactive=$8
    local play=$9
    
    site_info=$(wget -nv -qO - "$invidious/playlist?list=$id")
    
    playlist="$album"
    if [[ "$album" == '-' ]]; then
        playlist=$(echo "$site_info" | sed -n 's/.*title>\(.*\)<.*/\1/p')
        playlist=$(clean_playlist_name "$playlist" "$artist")
        echo "Derived playlist name: $playlist"
        if [[ "$interactive" == "true" ]]; then
            read -p "Enter alternative (empty for default): " answer
            [ "$answer" != '' ] && playlist="$answer"
        fi
    fi
    output="$output/$(concatenate_with_underscore "$playlist")"
    mkdir "$output"
    local input="-o \"$output\""

    [ "$artist" != '-' ] && input="$input -p \"$artist\""
    [ "$album" != '-' ] && input="$input -a \"$album\""
    [ "$thumbImage" == 'true' ] && input="$input -c"
    [ "$replace" == 'true' ] && input="$input -r"
    [ "$tag" == 'true' ] && input="$input -t"
    [ "$interactive" == 'true' ] && input="$input -v"

    ids=$(echo $site_info | sed -n 's/>/\n/gp' |  grep "watch?v=" |  sed -n 's/.*[?&]v=\([^&]*\).*/\1/p' | sed '$!N; /^\(.*\)\n\1$/!P; D')

    while IFS= read -r line;
    do
        echo 
        echo "\"$invidious/watch?v=$line\" $input" | xargs -o sh -c 'source "$1/yap.sh"; yap "${@:2}"' _  $YAP_PATH
    done < <(printf '%s\n' "$ids")

    if [[ "$play" != '' ]]; then
        echo -e "\nExecuting $play"
        $play "$output"
    fi

}

