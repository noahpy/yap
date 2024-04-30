# YAP (Youtube Audio Puller)
Download Audio from Invidious by link or automatic search by song name.

### Functionality
- Download audio by Invidious / YouTube / Apple Music Playlist link
- Download audio by search term
- Download playlists by Invidious / YouTube playlist link
- Automatically tag artist, album, cover to audio file

### Dependencies
- curl
- ffmpeg
- [tageditor](https://github.com/Martchus/tageditor?tab=readme-ov-file)

### Setup
Clone this repository and enter it, then run:
```
./install.sh
```
Replace .bashrc with your equivalent shell file.

### Usage
One can either specify the audio to be downloaded via link or search term.
If not specified, this program will derive song / artist name by itself 
and name the downloaded file accordingly.


Download from link (any link pointing to a YouTube / Invidious video):
```
yap "[LINK]"
```
Download by search:
```
yap "[SEARCH]"
```
Download by search with additional info:
```
yap "[SEARCH]" -p "[ARTIST]" -a "[ALBUM]"
```
Include cover into downloaded audio file:
```
yap "[LINK/SEARCH]" -c
```
Download by search but set song name:
```
yap "[SEARCH]" -s "[SONGNAME]"
```
Download multiple audios specified by playlist link:
```
yap "[PLAYLIST_LINK]"
```
Automatically edit audio tags with given info:
```
yap "[LINK/SEARCH]" -t
```



