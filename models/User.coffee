mongoose = require("mongoose")
bcrypt = require("bcrypt-nodejs")
crypto = require("crypto")
userSchema = new mongoose.Schema(
  email:
    type: String
    unique: true

  password: String
  facebook:
    type: String
    unique: true
    sparse: true

  twitter:
    type: String
    unique: true
    sparse: true

  google:
    type: String
    unique: true
    sparse: true

  github:
    type: String
    unique: true
    sparse: true

  tokens: Array
  profile:
    name:
      type: String
      default: ""

    gender:
      type: String
      default: ""

    location:
      type: String
      default: ""

    website:
      type: String
      default: ""

    picture:
      type: String
      default: ""
)

###
Hash the password for security.
###
userSchema.pre "save", (next) ->
  user = this
  SALT_FACTOR = 5
  return next()  unless user.isModified("password")
  bcrypt.genSalt SALT_FACTOR, (err, salt) ->
    return next(err)  if err
    bcrypt.hash user.password, salt, null, (err, hash) ->
      return next(err)  if err
      user.password = hash
      next()
      return

    return

  return

userSchema.methods.comparePassword = (candidatePassword, cb) ->
  bcrypt.compare candidatePassword, @password, (err, isMatch) ->
    return cb(err)  if err
    cb null, isMatch
    return

  return


###
Get a URL to a user's Gravatar email.
###
userSchema.methods.gravatar = (size, defaults) ->
  size = 200  unless size
  defaults = "retro"  unless defaults
  md5 = crypto.createHash("md5").update(@email)
  "https://gravatar.com/avatar/" + md5.digest("hex").toString() + "?s=" + size + "&d=" + defaults

module.exports = mongoose.model("User", userSchema)
