# YAP (Youtube Audio Puller)
Download Audio from Invidious by link or automatic search by song name.

### Dependencies
- curl
- ffmpeg

### Setup
Clone this repository, then run:
```
echo "source $(pwd)/yap.sh" >> ~/.bashrc
```
Replace .bashrc with your equivalent shell file.

### Usage
Download from link (any link pointing to a YouTube / Invidious video):
```
yap [LINK]
```
Download by search:
```
yap [SONG]
```
Download by search with additional info:
```
yap [SONG] -p [ARTIST] -a [ALBUM]
```
Include cover into downloaded audio file:
```
yap [LINK/SONG] -c
```
Automatically edit audio tags with given info (TBD):
```
yap [LINK/SONG] -t
```



