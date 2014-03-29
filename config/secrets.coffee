module.exports =
  mysql:
    host: 'spread.cz6vgpg0twvp.ap-northeast-1.rds.amazonaws.com'
    port: 3306
    user: 'spread'
    password: 'spread00'
    database: 'spread2'

  sessionSecret: "deadbeaf"
  sendgrid:
    user: "Your SendGrid Username"
    password: "Your SendGrid Password"

  nyt:
    key: "Your New York Times API Key"

  lastfm:
    api_key: "Your API Key"
    secret: "Your API Secret"

  facebook:
    clientID: "Your App ID"
    clientSecret: "Your App Secret"
    callbackURL: "/auth/facebook/callback"
    passReqToCallback: true

  github:
    clientID: "Your Client ID"
    clientSecret: "Your Client Secret"
    callbackURL: "/auth/github/callback"
    passReqToCallback: true

  twitter:
    consumerKey: "jOQzTXzdvkUoFuBmawIIQ"
    consumerSecret: "THXpCvuGwjNiwbPeYmTlugeo26bdZfuwuk0MNkf6nw"
    callbackURL: "/auth/twitter/callback"

  google:
    clientID: "Your Client ID"
    clientSecret: "Your Client Secret"
    callbackURL: "/auth/google/callback"
    passReqToCallback: true

  steam:
    apiKey: "Your Steam API Key"

  twilio:
    sid: "Your Account SID"
    token: "Your Auth Token"

  tumblr:
    consumerKey: "Your Consumer Key"
    consumerSecret: "Your Consumer Secret"
    callbackURL: "/auth/tumblr/callback"

  foursquare:
    clientId: "Your Client ID"
    clientSecret: "Your Client Secret"
    redirectUrl: "http://localhost:3000/auth/foursquare/callback"

  paypal:
    host: "api.sandbox.paypal.com" # or api.paypal.com
    client_id: "Your Client ID"
    client_secret: "Your Client Secret"
    returnUrl: "http://localhost:3000/api/paypal/success"
    cancelUrl: "http://localhost:3000/api/paypal/cancel"
