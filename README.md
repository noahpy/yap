# YAP (Youtube Audio Puller)
Downloads the .m4a audio of YouTube videos by getting them from a invidious instance. Also adds the cover image.

### Dependencies
- curl
- ffmpeg

### Setup
Clone this repository, then source yap.sh in your .bashrc / .zshrc equivalent.
```
source yap.sh
```

### Usage
Create a list with YouTube links and the wished filename without space in the name. 
Such as:
```
https://www.youtube.com/watch?v=zRSkjMPFggs after-laughter_argatu(remix)
https://www.youtube.com/watch?v=fkV9SH8IYoo wolf-totem_the-hu
```
Call with:
```
yap youtubelist.txt
```
