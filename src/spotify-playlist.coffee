# Description
#   Allows the ability to add/remove/findTracks to a Spotify Playlist.
#
# Configuration:
#   SPOTIFY_APP_CLIENT_ID
#   SPOTIFY_APP_CLIENT_SECRET
#   SPOTIFY_USER_ID
#   SPOTIFY_PLAYLIST_ID
#
# Commands:
#   hubot getToken - go to that link to get a token
#   hubot addTrack <track_id> key <oauth_token> - Adds a track to the playlist
#   hubot removeTrack <track_id> key <oauth_token> - Removes a track on the playlist
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Kevin Ngao (kev5873) <kevgong@yahoo.com>

authorizeApp = (res, func) ->
  encodedAppId = new Buffer(process.env.SPOTIFY_APP_CLIENT_ID + ":" + process.env.SPOTIFY_APP_CLIENT_SECRET).toString('base64')
  data = "grant_type=client_credentials"
  res.http("https://accounts.spotify.com/api/token")
    .header("Authorization", "Basic " + encodedAppId)
    .header('Content-Type', 'application/x-www-form-urlencoded')
    .post(data) (err, resp, body) =>
      response = JSON.parse(body)
      func(res, response.access_token)

addTrack = (res) ->
  res.http("https://api.spotify.com/v1/users/" + process.env.SPOTIFY_USER_ID + "/playlists/" + process.env.SPOTIFY_PLAYLIST_ID + "/tracks?uris=spotify%3Atrack%3A" + res.match[1])
    .header("Authorization", "Bearer " + res.match[2])
    .header('Content-Type', 'application/json')
    .header('Accept', 'application/json')
    .post() (err, resp, body) =>
      res.send "I think the track was added"

removeTrack = (res) ->
  data = JSON.stringify({
    tracks: [
      uri : "spotify:track:" + res.match[1]
    ]
  })
  res.http("https://api.spotify.com/v1/users/" + process.env.SPOTIFY_USER_ID + "/playlists/" + process.env.SPOTIFY_PLAYLIST_ID + "/tracks")
    .header("Authorization", "Bearer " + res.match[2])
    .header('Content-Type', 'application/json')
    .delete(data) (err, resp, body) =>
      res.send "I think the track was removed"

findTrack = (res, token) ->
  res.http("https://api.spotify.com/v1/search?q=" + res.match[1] + "&type=track&market=US&limit=10")
    .header("Authorization", "Bearer " + token)
    .header('Accept', 'application/json')
    .get() (err, resp, body) =>
      response = JSON.parse body
      for item in response.tracks.items
        res.send "#{item.name} - #{item.album.name} - #{item.id}"

module.exports = (robot) ->

  robot.hear /getToken/i, (res) ->
    res.send "https://developer.spotify.com/web-api/console/post-playlist-tracks/"

  robot.hear /addTrack (.*) key (.*)/i, (res) ->
    addTrack(res)

  robot.hear /removeTrack (.*) key (.*)/i, (res) ->
    removeTrack(res)

  robot.hear /findTrack (.*)/i, (res) ->
    authorizeApp(res, findTrack)