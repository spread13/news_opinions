module.exports =
  validEmail: (email) -> email && email.length >= 6
  validPassword: (pwd) -> pwd && pwd.length >= 4
  validCastName: (s) -> s?.length > 0
  validCastDescription: (s) -> s?.length > 0
  validPublishName: (s) -> s?.length > 0
  validArticleTitle: (s) -> s?.length > 0
  validURL: (s) -> s?.length > 0

## deprecated ##
  validUrl: (s) -> true
  validRss: (s) -> s.length > 0
  validTitle: (s) -> true
  toSqlSafe: (s) -> s.replace /\'/g, "\\'"
