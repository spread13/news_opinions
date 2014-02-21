module.exports = (code, msg) ->
  code = 500 unless msg
  err = {}
  err.status = code >= 1000 && 500 || code
  err.code = code >= 1000 && code || null
  err.message = msg
  err
