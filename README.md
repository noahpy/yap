# yt-audio-downloader
Downloads the audio of YouTube videos by getting them from a invidious instance. Also adds the cover image.

### Dependencies
- curl
- ffmpeg

### Usage
Create a list with YouTube links and the wished filename without space in the name. Like
```
https://www.youtube.com/watch?v=zRSkjMPFggs after-laughter_argatu(remix)
https://www.youtube.com/watch?v=fkV9SH8IYoo wolf-totem_the-hu
```
Call with:
```
$ bash yt-aduio-downloader.sh youtubelist.txt
```
