module.exports =
  validEmail: (email) -> email && email.length >= 6
  validPassword: (pwd) -> pwd && pwd.length >= 4
  validUrl: (s) -> true
  validRss: (s) -> s.length > 0
  validTitle: (s) -> true
  toSqlSafe: (s) -> s.replace /\'/g, "\\'"
