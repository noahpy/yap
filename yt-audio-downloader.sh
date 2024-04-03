#!/bin/bash

# run like following:
# $ bash yt-downloader.sh youtubelist.txt
# where youtubelist is of the following structure:
# youtubelink1 filename1
# youtubelink2 filename2

# If filename is not given, the title of the Video is taken

# invidious instance
invidious=https://yt.artemislena.eu
# temporary files path
tmp='/tmp/yt-download'

# itag for lowest quality m4a (https://gist.github.com/sidneys/7095afe4da4ae58694d128b1034e01e2)
itag=139

mkdir -p "$tmp" finish

list=$1


while read line;
do
  link=$(echo $line | awk -F' ' '{print $1}')

  # forward link to ensure parameter is in link (also work with bit.ly links)
  if [[ $link != *".com"* ]]; then
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

  echo -e "name=$name"

  # get audio .m4a
  echo "$invidious/latest_version?id=$id&itag=$itag"
  curl -Ls "$invidious/latest_version?id=$id&itag=$itag" -o "$tmp/$name.m4a"
  RC=$(echo $?)
  echo -e "curl audio: $RC" 

  # get cover image
  [ $RC -eq 0 ] && curl -Ls "$invidious/vi/$id/maxres.jpg" -o "$tmp/$name-cover.jpg"
  RC=$(echo $?)
  echo -e "curl picture: $RC" 

  # insert image to audio
  [ $RC -eq 0 ] && (ffmpeg -nostdin -i "$tmp/$name.m4a" -i "$tmp/$name-cover.jpg" -map 0:0 -map 1:0 -acodec copy -id3v2_version 3 "finish/$name.m4a") 2> /dev/null
  echo -e "ffmpeg put image in m4a: $?"


  # remove temporary files
  [ -f "$tmp/$name-cover.jpg" ] && rm "$tmp/$name-cover.jpg"
  [ -f "$tmp/$name.m4a" ] && rm "$tmp/$name.m4a"

  echo -e "rm temporary files: $?" 
done < $list

[ -f "$tmp" ] && rmdir "$tmp"
