# hubot-spotify-playlist

Allows the ability to add/remove/find tracks to a single collaborative Spotify Playlist.

See [`src/spotify-playlist.coffee`](src/spotify-playlist.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-spotify-playlist --save`

Then add **hubot-spotify-playlist** to your `external-scripts.json`:

```json
[
  "hubot-spotify-playlist"
]
```
## Pre-Setup

To get started, you need to create an app to use for the Spotify API.  [https://developer.spotify.com/my-applications](https://developer.spotify.com/my-applications)  Create an App, and enter in the details.  Next you will want to make note of the client id and secret, which you will enter in the Hubot Setup step, then add a redirect url, which will also be entered in the Hubot Setup step.  The redirect URL should be ideally something that works, so you can extract the code after the redirect.

Next you want to Authorize your app with a user.  You'll want to generate an authorize link to navigate to.  Replace client\_id and redirect\_uri which you should've gotten previously.

```text
https://accounts.spotify.com/authorize/?client_id=<client_id>&response_type=code&redirect_uri=<redirect_uri>&scope=playlist-modify-public%20playlist-modify-private
```

Navigate to this link, login with your Spotify account, and when the redirect is complete, there should be a code parameter on the URL.  Make note of this value which you will enter in the next step.

## Hubot Setup

There are environment variables that need to be set. ```SPOTIFY_APP_CLIENT_ID``` and ```SPOTIFY_APP_CLIENT_SECRET``` are required in order for the findTrack function to work. This needs a spotify app setup. The ```SPOTIFY_USER_ID``` and ```SPOTIFY_PLAYLIST_ID``` are needed to hard code the playlist we are modifying.  You should've gotten ```SPOTIFY_OAUTH_CODE``` and ```SPOTIFY_REDIRECT_URI``` from the pre-setup step.  This will allow you to actually add/modify your playlists.

```sh
SPOTIFY_APP_CLIENT_ID
SPOTIFY_APP_CLIENT_SECRET
SPOTIFY_USER_ID
SPOTIFY_PLAYLIST_ID
SPOTIFY_OAUTH_CODE
SPOTIFY_REDIRECT_URI
```

## User Usage

### Displaying Playlist Link

```sh
hubot playlist link
```

The link to the playlist will be displayed in chat.

### Finding tracks

```sh
hubot playlist find <query>
```

Make note of the track ID you want to add so you can add/remove it in the next step.

### Adding/Removing Tracks
Using the track id gotten from the last steps, or just putting a query in add you can either add or remove tracks.

```sh
hubot playlist add <query>
hubot playlist addid <track_id>
hubot playlist remove <track_id>
```

### Automatically Listening for Spotify Track Links
Control whether spotify links shared in chat are automatically added to the playlist

```sh
hubot playlist listen status
hubot playlist listen on
hubot playlist listen off
```