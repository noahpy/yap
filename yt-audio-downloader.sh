#!/bin/bash

# run like following:
# $ bash yt-downloader.sh youtubelist.txt
# where youtubelist is of the following structure:
# youtubelink filename

# curl -Ls https://invidious.13ad.de/watch?v=MB0vRra5fUI | grep -E '<title>.*</title>'
# invidious instance
invidous=https://invidious.13ad.de

filename=$1

mkdir -p tmp finish

while read line; 
do 

  name=$(echo $line | awk -F' ' '{print $2}')

  # Skip loop element, when file already exists
  [ -f finish/$name.m4a ] && continue

  link=$(echo $line | awk -F' ' '{print $1}')
  id=$(echo $link | sed -e 's/^.*\.com\/watch?v=//' -e 's/\&.*$//')
  # Vanced only uses 11 characters for their ids
  id=${id:0:11}

  echo -e "=====================\nname=$name\n====================="

  # get audio .webm
  curl -L "$invidous/latest_version?id=$id&itag=251" -o "tmp/$name.webm"
  RC=$(echo $?)
  echo -e "=====================\ncurl audio: $RC\n====================="
  echo "$invidous/latest_version?id=$id&itag=251" 

  # get cover image
  [ $RC -eq 0 ] && curl -L "$invidous/vi/$id/maxres.jpg" -o "tmp/$name-cover.jpg"
  RC=$(echo $?)
  echo -e "=====================\ncurl picture: $RC\n====================="

  # convert to m4a
  [ $RC -eq 0 ] && (ffmpeg -nostdin -i tmp/$name.webm -vn tmp/$name.m4a) 2> /dev/null
  RC=$(echo $?)
  echo -e "=====================\nffmpeg convert to m4a: $RC\n====================="

  # insert image to audio
  [ $RC -eq 0 ] && (ffmpeg -nostdin -i tmp/$name.m4a -i tmp/$name-cover.jpg -map 0:0 -map 1:0 -acodec copy -id3v2_version 3 finish/$name.m4a) 2> /dev/null
  echo -e "=====================\nffmpeg put image in m4a: $?\n====================="

  # remove temporary files
  rm tmp/$name-cover.jpg tmp/$name.webm tmp/$name.m4a

  echo -e "=====================\nrm tmp: $?\n====================="
done < $filename

echo -e "=====================\n$?\n====================="
rmdir tmp
