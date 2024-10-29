# YAP (Youtube Audio Puller)
Download Audio from Invidious by link or automatic search by song name.

### Table of Contents

- [Functionality](#functionality)
- [Dependencies](#dependencies)
- [Setup](#setup)
- [Usage](#usage)
- [Recommended invidious server + itag](#recommended-invidious-server-itag)
- [Spotify Download](#spotify-download)

### Functionality
- Download audio by Invidious / YouTube link
- Download audio by search term
- Download playlists by Invidious / YouTube / Apple Music playlist link
- Automatically tag artist, album, cover to audio file

### Dependencies
- curl
- ffmpeg
- [tageditor-cli](https://github.com/Martchus/tageditor?tab=readme-ov-file)

### Setup
**AUR**:
```
yay -S youtube-audio-puller-git
```
**From source**:  
Clone this repository and enter it, then run:
```
./install.sh
```
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

### Recommended invidious server + itag
As of October 2024, the default server and itag seem to have some problems. Instead, use `yap` with:
```
yap "[INPUT]" --invidious="https://inv.nadeko.net" -i 140
```

### Spotify Download
Downloading spotify playlists is still in development,
but one could use [spotDL](https://github.com/spotDL/spotify-downloader) for that purpose.




