config = require("../config/config")
Err = require("../lib/err")
VD = require("../lib/validator")


exports.create = (req, res, next) ->
  castId = parseInt req.params.id
  return next(Err 400, "Invalid id") if isNaN castId
  unless VD.validPublishName(name = req.body.name)
    return next(Err 400, "Invalid Cast Name")

  req.getConnection (err, conn) ->
    return next(err) if err

    sql = 'insert into papers (cast_id, name) values (?,?);'
    conn.query sql, [castId, name], (err) ->
      return next(err) if err
      res.json {}


exports.list = (req, res, next) ->
  castId = parseInt req.params.id
  return next(Err 400, "Invalid id") if isNaN castId

  req.getConnection (err, conn) ->
    return next(err) if err

    sql = "select * from papers where cast_id = ?;"
    conn.query sql, [castId], (err, rows) ->
      return next(err) if err
      res.json rows



exports.del = (req, res, next) ->
  paperId = parseInt req.params.id
  return next(Err 400, "Invalid id") if isNaN paperId

  req.getConnection (err, conn) ->
    return next(err) if err

    sql = 'select * from user_casts as uc, papers as p where p.id = ? and p.cast_id = uc.cast_id and uc.user_id = ?;'
    conn.query sql, [paperId, req.user.id], (err, data) ->
      return next(err) if err
      return next(Err 400, "No permission") unless data

      sql = 'delete from papers where id=?;'
      conn.query sql, [paperId], (err) ->
        return next(err) if err
        res.json {}



exports.publish = (req, res, next) ->

