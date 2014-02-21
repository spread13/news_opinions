module.exports =
  validEmail: (email) -> email && email.length >= 6
  validPassword: (pwd) -> pwd && pwd.length >= 4
