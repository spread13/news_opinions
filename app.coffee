###
Module dependencies.
###
createDomain = require('domain').create
express = require("express")
flash = require("express-flash")
path = require("path")
passport = require("passport")
LocalStrategy = require("passport-local").Strategy
expressValidator = require("express-validator")
bcrypt = require("bcrypt-nodejs")
mysql = require("mysql")
_ = require("underscore")
hbs = require("express-hbs")
i18n = require("i18n")

###
Load controllers.
###
homeController = require("./controllers/home")
userController = require("./controllers/user")
apiController = require("./controllers/api")
contactController = require("./controllers/contact")

###
API keys + Passport configuration.
###
secrets = require("./config/secrets")

pool = mysql.createPool secrets.mysql

passport.serializeUser (user, done) ->
  done null, user.id

passport.deserializeUser (id, done) ->
  pool.getConnection (err, conn) ->
    conn.query 'select * from users', (err, rows) ->
      done(err, rows?[0])
      conn.release()

passport.use new LocalStrategy {usernameField: "email"}, (email, password, done) ->
  pool.getConnection (err, conn) ->
    conn.query 'select email, password from users', (err, rows) ->
      unless user = rows[0]
        return done(null, false, message: "Email #{email} not found")
      bcrypt.compare password, user.password, (err, isMatch) ->
        return done(err) if err
        return done(null, user) if isMatch
        done null, false, message: "Invalid email or password."
        
isAuthenticated = (req, res, next) ->
  return next() if req.isAuthenticated()
  res.redirect "/login"

isAuthorized = (req, res, next) ->
  provider = req.path.split("/").slice(-1)[0]
  if _.findWhere(req.user.tokens, kind: provider)
    next()
  else
    res.redirect "/auth/" + provider

###
Create Express server.
###
app = express()

###
Express configuration.
###

i18n.configure
  locales: ['en', 'kr']
  defaultLocale: "en"
  cookie: 'locale'
  directory: __dirname + "/locales"
  indent: "  "
  extension: ".js"

hour = 3600000
day = (hour * 24)
week = (day * 7)
month = (day * 30)
app.set "port", process.env.PORT or 3333
###
app.engine 'hbs', hbs.express3
  partialsDir: __dirname+'/views/partials'
  defaultLayout: __dirname+'/views/layout.hbs'
  i18n: i18n
app.set "views", path.join(__dirname, "views")
app.set "view engine", "hbs"
###
app.set "views", path.join(__dirname, "jade")
app.set "view engine", "jade"
app.use require("connect-assets")(
  src: "public"
  helperContext: app.locals
)
app.use express.compress()
app.use express.favicon()
app.use express.logger("dev")
app.use express.static(path.join(__dirname, "public"), maxAge: week)
app.use express.cookieParser()
app.use i18n.init
app.use express.json()
app.use express.urlencoded()
app.use expressValidator()
app.use express.methodOverride()
app.use (req, res, next) ->
  domain = createDomain()
  domain.on 'error', next
  domain.run next
app.use express.cookieSession
  key: 'sid'
  secret: secrets.sessionSecret
app.use express.csrf()
app.use passport.initialize()
app.use passport.session()
app.use (req, res, next) ->
  res.locals.user = req.user
  res.locals.token = req.csrfToken()
  next()
app.use flash()
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
app.use (req, res) ->
  res.status 404
  res.render "404"
app.use express.errorHandler()

###
Application routes.
###
app.get "/", homeController.index
app.get "/login", userController.getLogin
app.post "/login", userController.postLogin
app.get "/logout", userController.logout
app.get "/signup", userController.getSignup
app.post "/signup", userController.postSignup
app.get "/contact", contactController.getContact
app.post "/contact", contactController.postContact
app.get "/account", isAuthenticated, userController.getAccount
app.post "/account/profile", isAuthenticated, userController.postUpdateProfile
app.post "/account/password", isAuthenticated, userController.postUpdatePassword
app.post "/account/delete", isAuthenticated, userController.postDeleteAccount
app.get "/account/unlink/:provider", isAuthenticated, userController.getOauthUnlink
app.get "/test", (req, res, next) ->
  res.render "test.html", title: "Test"
app.get "/api", apiController.getApi
app.get "/api/lastfm", apiController.getLastfm
app.get "/api/nyt", apiController.getNewYorkTimes
app.get "/api/aviary", apiController.getAviary
app.get "/api/paypal", apiController.getPayPal
app.get "/api/paypal/success", apiController.getPayPalSuccess
app.get "/api/paypal/cancel", apiController.getPayPalCancel
app.get "/api/steam", apiController.getSteam
app.get "/api/scraping", apiController.getScraping
app.get "/api/twilio", apiController.getTwilio
app.post "/api/twilio", apiController.postTwilio
app.get "/api/foursquare", isAuthenticated, isAuthorized, apiController.getFoursquare
app.get "/api/tumblr", isAuthenticated, isAuthorized, apiController.getTumblr
app.get "/api/facebook", isAuthenticated, isAuthorized, apiController.getFacebook
app.get "/api/github", isAuthenticated, isAuthorized, apiController.getGithub
app.get "/api/twitter", isAuthenticated, isAuthorized, apiController.getTwitter

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
app.get "/auth/twitter", passport.authenticate("twitter")
app.get "/auth/twitter/callback", passport.authenticate("twitter",
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

