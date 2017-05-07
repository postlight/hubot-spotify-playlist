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
#   hubot playlist link - displays link to spotify playlist
#   hubot playlist listen <on|off|status> - controls whether it should be listening for spotify links to automatically add
#
# Author:
#   Kevin Ngao (kev5873) <kevgong@yahoo.com>



module.exports = (robot) ->

  # init listen flag to false if none can be found
  if (robot.brain.get('playlistListen') == null)
    robot.brain.set 'playlistListen', false

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

  robot.respond /playlist add (.*)/i, (res) ->
    authorizeAppUser(res, findAndAddFirstTrack)

  robot.respond /playlist addid (.*)/i, (res) ->
    authorizeAppUser(res, addTrack)

  robot.respond /playlist remove (.*)/i, (res) ->
    authorizeAppUser(res, removeTrack)

  robot.respond /playlist find (.*)/i, (res) ->
    authorizeApp(res, findTrack)

  robot.respond /playlist listen (on|off|status)/i, (res) ->
    if (res.match[1] == "on")
      robot.brain.set 'playlistListen', true
      res.send "Now listening for spotify links!"
    else if (res.match[1] == "off")
      robot.brain.set 'playlistListen', false
      res.send "No longer listening for spotify links."
    else
      listenStatus = robot.brain.get('playlistListen')
      value = if listenStatus then "on" else "off"
      res.send "Listening status: " + value

  robot.hear /https:\/\/open\.spotify\.com\/track\/([a-zA-Z\d]+)\s*?/i, (res) ->
    if (robot.brain.get('playlistListen'))
      authorizeAppUser(res, addTrack)

  robot.respond /playlist link/i, (res) ->
    res.send "https://open.spotify.com/user/#{process.env.SPOTIFY_USER_ID}/playlist/#{process.env.SPOTIFY_PLAYLIST_ID}"
