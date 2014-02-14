passport = require("passport")
_ = require("underscore")

###
GET /login
Login page.
###
exports.getLogin = (req, res) ->
  return res.redirect("/") if req.user
  res.render "account/login", title: "Login"


###
POST /login
Sign in using email and password.
@param email
@param password
###
exports.postLogin = (req, res, next) ->
  req.assert("email", "Email is not valid").isEmail()
  req.assert("password", "Password cannot be blank").notEmpty()
  errors = req.validationErrors()
  if errors
    req.flash "errors", errors
    return res.redirect("/login")
  passport.authenticate("local", (err, user, info) ->
    return next(err)  if err
    unless user
      req.flash "errors", msg: info.message
      return res.redirect("/login")
    req.logIn user, (err) ->
      return next(err) if err
      res.redirect "/"
  ) req, res, next


###
GET /logout
Log out.
###
exports.logout = (req, res) ->
  req.logout()
  res.redirect "/"


###
GET /signup
Signup page.
###
exports.getSignup = (req, res) ->
  return res.redirect("/") if req.user
  res.render "account/signup", title: "Create Account"


###
POST /signup
Create a new local account.
@param email
@param password
###
exports.postSignup = (req, res, next) ->
  req.assert("email", "Email is not valid").isEmail()
  req.assert("password", "Password must be at least 4 characters long").len 4
  req.assert("confirmPassword", "Passwords do not match").equals req.body.password
  errors = req.validationErrors()
  if errors
    req.flash "errors", errors
    return res.redirect("/signup")
 
  req.getConnection (err, conn) ->
    return next(err) if err
    conn.query "select email from users where email = ?", [req.body.email], (err, rows) ->
      return next(err) if err
      if rows.length > 0
        req.flash "errors", msg: "User with that email already exists."
        return res.redirect("/signup")

      conn.query "insert into users (email, password) values (?, ?)", [req.body.email, req.body.password], (err) ->
        return next(err) if err
        conn.query "select * from users where email = ?", [req.body.email], (err, rows) ->
          return next(err) if err
          req.logIn rows[0], (err) ->
            return next(err) if err
            res.redirect "/"


###
GET /account
Profile page.
###
exports.getAccount = (req, res) ->
  res.render "account/profile", title: "Account Management"


###
POST /account/profile
Update profile information.
###
exports.postUpdateProfile = (req, res, next) ->
  req.getConnection (err, conn) ->
    return next(err) if err
    conn.query "select * from users where id = ?", [req.user.id], (err,rows) ->
      return next(err) if err
      user = rows[0]
      conn.query "update users set email = ?, name = ? where id = ?", [req.body.email || user.email, req.body.name || user.name, req.user.id], (err) -> 
        return next(err)  if err
        req.flash "success", msg: "Profile information updated."
        res.redirect "/account"


###
POST /account/password
Update current password.
@param password
###
exports.postUpdatePassword = (req, res, next) ->
  req.assert("password", "Password must be at least 4 characters long").len 4
  req.assert("confirmPassword", "Passwords do not match").equals req.body.password
  errors = req.validationErrors()
  if errors
    req.flash "errors", errors
    return res.redirect("/account")

  req.getConnection (err, conn) ->
    return next(err) if err
    conn.query "select * from users where id = ?", [req.user.id], (err,rows) ->
      return next(err)  if err
      user = rows[0]
      conn.query "update users set password = ? where id = ?", [req.body.password, req.user.id], (err) -> 
        return next(err)  if err
        req.flash "success", msg: "Password has been changed."
        res.redirect "/account"
  

###
POST /account/delete
Delete user account.
@param id - User ObjectId
###
exports.postDeleteAccount = (req, res, next) ->
  req.getConnection (err, conn) ->
    return next(err) if err
    conn.query 'delete from users where id = ?', [req.user.id], (err) ->
      return next(err)  if err
      req.logout()
      res.redirect "/"


###
GET /account/unlink/:provider
Unlink OAuth2 provider from the current user.
@param provider
@param id - User ObjectId
###
exports.getOauthUnlink = (req, res, next) ->
  provider = req.params.provider
  User.findById req.user.id, (err, user) ->
    return next(err)  if err
    user[provider] = `undefined`
    user.tokens = _.reject(user.tokens, (token) ->
      token.kind is provider
    )
    user.save (err) ->
      return next(err)  if err
      req.flash "info",
        msg: provider + " account has been unlinked."

      res.redirect "/account"
      return

    return

  return
