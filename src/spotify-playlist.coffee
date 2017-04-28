# Description
#   Allows the ability to add/remove/findTracks to a Spotify Playlist.
#
# Configuration:
#   SPOTIFY_APP_CLIENT_ID
#   SPOTIFY_APP_CLIENT_SECRET
#   SPOTIFY_USER_ID
#   SPOTIFY_PLAYLIST_ID
#   SPOTIFY_OAUTH_CODE
#   SPOTIFY_REDIRECT_URI
#
# Commands:
#   hubot playlist add <query> - Adds first track in search to the playlist
#   hubot playlist addid <track_id> - Adds a track to the playlist via ID
#   hubot playlist remove <track_id>  - Removes a track on the playlist
#   hubot playlist find <query> - go to that link to get a token
#
# Author:
#   Kevin Ngao (kev5873) <kevgong@yahoo.com>



module.exports = (robot) ->

  # Authorize app, only authorizes non-user specific functions for the app, like Searching.
  # See: https://developer.spotify.com/web-api/authorization-guide/#client_credentials_flow

  authorizeApp = (res, func) ->
    encodedAppId = new Buffer(process.env.SPOTIFY_APP_CLIENT_ID + ":" + process.env.SPOTIFY_APP_CLIENT_SECRET).toString('base64')
    data = "grant_type=client_credentials"
    res.http("https://accounts.spotify.com/api/token")
      .header("Authorization", "Basic " + encodedAppId)
      .header('Content-Type', 'application/x-www-form-urlencoded')
      .post(data) (err, resp, body) =>
        response = JSON.parse(body)
        func(res, response.access_token)

  # Authorize App User Flow, authorizes user specific functions, like modifying playlists
  # See: https://developer.spotify.com/web-api/authorization-guide/#authorization_code_flow

  requestInitialTokens = (res, func) ->
    encodedAppId = new Buffer(process.env.SPOTIFY_APP_CLIENT_ID + ":" + process.env.SPOTIFY_APP_CLIENT_SECRET).toString('base64')
    data = "grant_type=authorization_code&code=" + process.env.SPOTIFY_OAUTH_CODE +  "&redirect_uri=" + process.env.SPOTIFY_REDIRECT_URI
    res.http("https://accounts.spotify.com/api/token")
      .header("Authorization", "Basic " + encodedAppId)
      .header('Content-Type', 'application/x-www-form-urlencoded')
      .post(data) (err, resp, body) =>
        response = JSON.parse(body)
        if response.error
          res.send "An error occured, " + response.error_description
        robot.brain.set 'access_token', response.access_token
        robot.brain.set 'refresh_token', response.refresh_token
        robot.brain.set 'expires', (new Date().getTime() + (response.expires_in * 1000))
        func(res)

  refreshAccessToken = (res, func) ->
    console.log 'refreshAccessToken', robot
    encodedAppId = new Buffer(process.env.SPOTIFY_APP_CLIENT_ID + ":" + process.env.SPOTIFY_APP_CLIENT_SECRET).toString('base64')
    data = "grant_type=refresh_token&refresh_token=" + robot.brain.get('refresh_token')
    res.http("https://accounts.spotify.com/api/token")
      .header("Authorization", "Basic " + encodedAppId)
      .header('Content-Type', 'application/x-www-form-urlencoded')
      .post(data) (err, resp, body) =>
        response = JSON.parse(body)
        if response.refresh_token
          robot.brain.set 'refresh_token', response.refresh_token
        robot.brain.set 'access_token', response.access_token
        robot.brain.set 'expires', (new Date().getTime() + (response.expires_in * 1000))
        func(res)

  authorizeAppUser = (res, func) ->
    if (robot.brain.get('access_token') != null) # Access Token Exists
      if ((new Date().getTime()) > robot.brain.get('expires')) # Token expired
        refreshAccessToken(res, func)
      else # Token has not expired, continue using it
        func(res)
    else # access token doesn't exist
      requestInitialTokens(res, func)

  # Spotify Web API Functions

  addTrack = (res) ->
    res.http("https://api.spotify.com/v1/users/" + process.env.SPOTIFY_USER_ID + "/playlists/" + process.env.SPOTIFY_PLAYLIST_ID + "/tracks?uris=spotify%3Atrack%3A" + res.match[1])
      .header("Authorization", "Bearer " + robot.brain.get('access_token'))
      .header('Content-Type', 'application/json')
      .header('Accept', 'application/json')
      .post() (err, resp, body) =>
        response = JSON.parse(body)
        if response.snapshot_id
          res.send "Track added"

  findAndAddFirstTrack = (res, token) ->
    res.http("https://api.spotify.com/v1/search?q=" + res.match[1] + "&type=track&market=US&limit=1")
      .header("Authorization", "Bearer " + token)
      .header('Accept', 'application/json')
      .get() (err, resp, body) =>
        response = JSON.parse body
        for item in response.tracks.items
          res.match[1] = item.id
        authorizeAppUser(res, addTrack)

  removeTrack = (res) ->
    data = JSON.stringify({
      tracks: [
        uri : "spotify:track:" + res.match[1]
      ]
    })
    res.http("https://api.spotify.com/v1/users/" + process.env.SPOTIFY_USER_ID + "/playlists/" + process.env.SPOTIFY_PLAYLIST_ID + "/tracks")
      .header("Authorization", "Bearer " + robot.brain.get('access_token'))
      .header('Content-Type', 'application/json')
      .delete(data) (err, resp, body) =>
        response = JSON.parse(body)
        if response.snapshot_id
          res.send "Track removed"

  findTrack = (res, token) ->
    res.http("https://api.spotify.com/v1/search?q=" + res.match[1] + "&type=track&market=US&limit=10")
      .header("Authorization", "Bearer " + token)
      .header('Accept', 'application/json')
      .get() (err, resp, body) =>
        response = JSON.parse body
        string = ""
        for item in response.tracks.items
          string = string + "#{item.name} - #{item.artists[0].name} - #{item.album.name} - #{item.id} \n"
        res.send string

  robot.hear /playlist add (.*)/i, (res) ->
    authorizeAppUser(res, findAndAddFirstTrack)

  robot.hear /playlist addid (.*)/i, (res) ->
    authorizeAppUser(res, addTrack)

  robot.hear /playlist remove (.*)/i, (res) ->
    authorizeAppUser(res, removeTrack)

  robot.hear /playlist find (.*)/i, (res) ->
    authorizeApp(res, findTrack)

  robot.hear /https:\/\/open\.spotify\.com\/track\/([a-zA-Z\d]+)\s*?/i, (res) ->
    authorizeAppUser(res, addTrack)
