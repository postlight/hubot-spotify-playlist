# hubot-spotify-playlist

Allows the ability to add/remove/findTracks to a Spotify Playlist.

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

## Notes
A handful of caveats unfortunately. The ability to modify a playlist is a user data level access, which means you need to be logged in ([https://developer.spotify.com/web-api/authorization-guide/#supported-authorization-flows](https://developer.spotify.com/web-api/authorization-guide/#supported-authorization-flows). For now we can only modify a single playlist.

## Hubot Setup

There are environment variables that need to be set. ```SPOTIFY_APP_CLIENT_ID``` and ```SPOTIFY_APP_CLIENT_SECRET``` are required in order for the findTrack function to work. This needs a spotify app setup. The ```SPOTIFY_USER_ID``` and ```SPOTIFY_PLAYLIST_ID``` are needed to hard code the playlist we are modifying.

```sh
SPOTIFY_APP_CLIENT_ID
SPOTIFY_APP_CLIENT_SECRET
SPOTIFY_USER_ID
SPOTIFY_PLAYLIST_ID
```

## User Usage

### To search do

```sh
bot findTrack <query>
```

Make note of the track ID you want to add so you can add/remove it in the next step.

### Getting an OAuth token.
Visit https://developer.spotify.com/web-api/console/post-playlist-tracks/ this link is outputted when you type

```sh
bot getToken
```

Click Get OAuth Token, and check the two relevant scopes and click request token. You should be prompted to login and allow. Once that is done, an OAuth token will be present in the box. Make note of this token as you will need it.  You will need another one when it expires. I'd recommend talking to the bot directly, so you don't expose your OAuth token to everyone.

### Adding/Removing
Using the OAuth token and track id gotten from the last two steps, you can either add or remove tracks.

```sh
bot addTrack <track_id> key <oauth_token>
bot removeTrack <track_id> key <oauth_token>
```