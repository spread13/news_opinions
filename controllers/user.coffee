crypto = require("crypto")
jwt = require("jwt-simple")
passport = require("passport")
_ = require("underscore")
config = require("../config/config")
Err = require("../lib/err")
VD = require("../lib/validator")

createToken = (user) ->
  profile =
    id: user.id
    expires: (Math.floor(Date.now()/60000) + config.tokenExpires)
  profile.name = user.name if user.name

  res =
    id: jwt.encode(profile, config.secret)
    expires: profile.expires
  res.name = profile.name if profile.name
  res

encPassword = (pwd) ->
  try
    sha1 = crypto.createHash('sha1')
    sha1.update(pwd + config.salt).digest('hex')
  catch
    null

###
POST /login
Sign in using email and password.
@param email, password
###
exports.postLogin = (req, res, next) ->
  unless VD.validEmail(req.body.email)
    return next(Err 400, "Invalid Email")
  unless VD.validPassword(req.body.password)
    return next(Err 400, "Invalid Password")

  req.getConnection (err, conn) ->
    return next(err) if err

    conn.query 'select * from users where email = ?', [req.body.email], (err, rows) ->
      unless user = rows[0]
        return next(Err 404, "No such user")
      if encPassword(req.body.password) != user.password
        return next(Err 400, "Invalid email or password")
      res.json {token: createToken(user)}, 201

###
POST /signup
Create a new local account.
@param email, password
###
exports.postSignup = (req, res, next) ->
  unless VD.validEmail(req.body.email)
    return next(Err 400, "Invalid Email")
  unless VD.validPassword(req.body.password)
    return next(Err 400, "Invalid Password")

  req.getConnection (err, conn) ->
    return next(err) if err
    conn.query "select email from users where email = ?", [req.body.email], (err, rows) ->
      return next(err) if err
      if rows.length > 0
        return next(Err 400, "User with that email already exists.")

      conn.query "insert into users (email, password) values (?, ?)", [req.body.email, encPassword(req.body.password)], (err) ->
        return next(err) if err
        conn.query "select * from users where email = ?", [req.body.email], (err, rows) ->
          return next(err) if err
          res.json {}



###
###
exports.get = (req, res, next) ->
  req.getConnection (err, conn) ->
    return next(err) if err
    conn.query "select * from users where id = ?", [req.user.id], (err,rows) ->
      return next(err) if err
      return next(Err 401, "No such user") if rows.length == 0

      user = rows[0]
      delete user.password
      res.json user

###
@params: email, name
###
exports.update = (req, res, next) ->
  req.getConnection (err, conn) ->
    return next(err) if err
    conn.query "select * from users where id = ?", [req.user.id], (err,rows) ->
      return next(err) if err
      return next(404, "No such user") if rows.length == 0

      user = rows[0]
      user.email = req.body.email if req.body.email
      user.name = req.body.name if req.body.name
      conn.query "update users set email = ?, name = ? where id = ?", [user.email, user.name, req.user.id], (err) -> 
        return next(err)  if err
        res.json {token: createToken(user)}, 201

###
###
exports.del = (req, res, next) ->
  req.getConnection (err, conn) ->
    return next(err) if err
    conn.query "delete from users where id = ?", [req.user.id], (err) ->
      return next(err) if err
      res.json {}


