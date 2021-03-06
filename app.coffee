###
Module dependencies.
###
createDomain = require('domain').create
express = require("express")
path = require("path")
passport = require("passport")
LocalStrategy = require("passport-local").Strategy
expressValidator = require("express-validator")
jwt = require("jwt-simple")
mysql = require("mysql")
_ = require("underscore")
OAuth = require('oauth').OAuth
config = require("./config/config")
Err = require("./lib/err")

###
Load controllers.
###
userController = require("./controllers/user")
siteController = require("./controllers/site")
opinionController = require("./controllers/opinion")

###
API keys + Passport configuration.
###
secrets = require("./config/secrets")

pool = mysql.createPool _.extend {multipleStatements:true, debug:true}, secrets.mysql

auth = (req, res, next) ->
  unless token = req.headers.authorization
    return next(Err 401, 'No auth token')

  payload = try
    jwt.decode token, config.secret
  catch
    null
  return next(Err 401, "Invalid token") unless payload && payload.id

  if Date.now() > payload.expires * 60000
    return next(Err 401, 'Token has expired')

  delete payload.expires
  req.user = payload
  next()
        
###
Create Express server.
###
app = express()

###
Express configuration.
###

hour = 3600000
day = (hour * 24)
week = (day * 7)
month = (day * 30)
app.set "port", process.env.PORT or 3333

app.use express.logger("dev")

app.use express.cookieParser()
app.use express.json()
app.use express.urlencoded()
app.use express.session
  key: 'sid'
  secret: config.secret
app.use expressValidator()
app.use express.methodOverride()
app.use (req, res, next) ->
  res.header 'Access-Control-Allow-Origin', config.allowDomains
  res.header 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,PATCH'
  res.header 'Access-Control-Allow-Headers', 'X-Requested-With,Authorization,Accept,Content-Type'
  if req.method == 'OPTIONS' then res.send 200
  else next()
app.use (req, res, next) ->
  domain = createDomain()
  domain.on 'error', next
  domain.run next
app.use passport.initialize()
app.use (req, res, next) ->
  poolConn = null
  req.getConnection = (cb) ->
    return cb(null, poolConn) if poolConn
    pool.getConnection (err, conn) ->
      cb(err) if err
      poolConn = conn
      cb(null, poolConn)

  end = res.end
  res.end = (data, encoding) ->
    poolConn.release() if poolConn
    res.end = end
    res.end(data, encoding)
  next()
    
app.use app.router
app.use (req, res) -> res.send 404
app.use (err, req, res, next) ->
  if err.stack
    console.log err.stack
    res.json {message: err.message}, 500
  else
    console.log [err.status, err.code, err.message]
    res.json {code: err.code, message: err.message}, err.status

###
Application routes.
###

app.post "/sites/twitter", auth, siteController.addTwitter
app.post "/sites", auth, siteController.create
app.get "/sites", auth, siteController.list
app.get "/sites/:id/articles", auth, siteController.articles
app.del "/sites/:id", auth, siteController.del
app.get "/articles", auth, siteController.myArticles

app.post "/articles/:id/opinions", auth, opinionController.create
app.get "/users/:id/opinions", auth, opinionController.list

app.post "/login", userController.postLogin
app.post "/users", userController.postSignup
app.get "/me", auth, userController.get
app.put "/me", auth, userController.update
app.del "/me", auth, userController.del

twitterOauth = new OAuth(
  'https://api.twitter.com/oauth/request_token',
  'https://api.twitter.com/oauth/access_token',
  secrets.twitter.consumerKey,
  secrets.twitter.consumerSecret,
  '1.0A',
  null,
  'HMAC-SHA1'
)

app.get "/auth/twitter", (req, res, next) ->
  twitterOauth.getOAuthRequestToken (err, token, tokenSecret, result) ->
    return res.send("Authentication fail") if err
    req.session.oauth =
      token: token
      tokenSecret: tokenSecret
    res.redirect "https://api.twitter.com/oauth/authenticate?oauth_token=#{token}"
   
app.get "/auth/twitter/callback", (req, res, next) ->
  oauth = req.session.oauth
  twitterOauth.getOAuthAccessToken(
    oauth.token,
    oauth.tokenSecret,
    req.query.oauth_verifier,
    (err, accessToken, accessSecret, result) ->
      return res.send("fail") if err
      req.session.oauth =
        accessToken: accessToken
        accessSecret: accessSecret
      res.send("<script>window.close();</script>")
  )

###
OAuth routes for sign-in.
###
app.get "/auth/facebook", passport.authenticate("facebook",
  scope: [
    "email"
    "user_location"
  ]
)
app.get "/auth/facebook/callback", passport.authenticate("facebook",
  successRedirect: "/"
  failureRedirect: "/login"
)
app.get "/auth/github", passport.authenticate("github")
app.get "/auth/github/callback", passport.authenticate("github",
  successRedirect: "/"
  failureRedirect: "/login"
)
app.get "/auth/google", passport.authenticate("google",
  scope: "profile email"
)
app.get "/auth/google/callback", passport.authenticate("google",
  successRedirect: "/"
  failureRedirect: "/login"
)


###
OAuth routes for API examples that require authorization.
###
app.get "/auth/foursquare", passport.authorize("foursquare")
app.get "/auth/foursquare/callback", passport.authorize("foursquare",
  failureRedirect: "/api"
), (req, res) ->
  res.redirect "/api/foursquare"
  return

app.get "/auth/tumblr", passport.authorize("tumblr")
app.get "/auth/tumblr/callback", passport.authorize("tumblr",
  failureRedirect: "/api"
), (req, res) ->
  res.redirect "/api/tumblr"
  return


###
Start Express server.
###
app.listen app.get("port"), ->
  console.log "✔ Express server listening on port %d in %s mode", app.get("port") , app.settings.env

