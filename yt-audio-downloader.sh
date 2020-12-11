#!/bin/bash

# run like following:
# $ bash yt-downloader.sh youtubelist.txt
# where youtubelist is of the following structure:
# youtubelink1 filename1
# youtubelink2 filename2

# If filename is not given, the title of the Video is taken

# invidious instance
invidous=https://invidious.13ad.de
# temporary files path
tmp='/tmp/yt-download'

mkdir -p "$tmp" finish

list=$1


while read line;
do
  link=$(echo $line | awk -F' ' '{print $1}')
  id=$(echo $link | sed -e 's/^.*\.com\/watch?v=//' -e 's/\&.*$//')
  # Vanced only uses 11 characters for their ids
  id=${id:0:11}

  # Get given Name
  name=$(echo $line | awk -F' ' '{print $2}')

  # If name is not given, take title of the video
  [ "$name" == '' ] && name=$(curl -Ls "https://invidious.13ad.de/watch?v=$id" | awk -F\" '/"title":/{ print $4 }')

  # Skip loop element, when file already exists
  [ -f finish/"$name".m4a ] && echo -e "Skipping \"$name\", because it already exists" && continue

  echo -e "=====================\nname=$name\n====================="

  # get audio .webm
  curl -Ls "$invidous/latest_version?id=$id&itag=251" -o "$tmp/$name.webm"
  RC=$(echo $?)
  echo -e "=====================\ncurl audio: $RC\n====================="
  echo "$invidous/latest_version?id=$id&itag=251"

  # get cover image
  [ $RC -eq 0 ] && curl -Ls "$invidous/vi/$id/maxres.jpg" -o "$tmp/$name-cover.jpg"
  RC=$(echo $?)
  echo -e "=====================\ncurl picture: $RC\n====================="

  # convert to m4a
  [ $RC -eq 0 ] && (ffmpeg -nostdin -i "$tmp/$name.webm" -vn "$tmp/$name.m4a") 2> /dev/null
  RC=$(echo $?)
  echo -e "=====================\nffmpeg convert to m4a: $RC\n====================="

  # insert image to audio
  [ $RC -eq 0 ] && (ffmpeg -nostdin -i "$tmp/$name.m4a" -i "$tmp/$name-cover.jpg" -map 0:0 -map 1:0 -acodec copy -id3v2_version 3 "finish/$name.m4a") 2> /dev/null
  echo -e "=====================\nffmpeg put image in m4a: $?\n====================="

  # remove temporary files
  [ -f "$tmp/$name-cover.jpg" ] && rm "$tmp/$name-cover.jpg"
  [ -f "$tmp/$name.webm" ] && rm "$tmp/$name.webm"
  [ -f "$tmp/$name.m4a" ] && rm "$tmp/$name.m4a"

  echo -e "=====================\nrm temporary directory: $?\n====================="
done < $list

[ -f "$tmp" ] && rmdir "$tmp"
