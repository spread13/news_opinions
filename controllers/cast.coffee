config = require("../config/config")
Err = require("../lib/err")
VD = require("../lib/validator")


# @params: name, description
exports.create = (req, res, next) ->
  unless VD.validCastName(name = req.body.name)
    return next(Err 400, "Invalid Cast Name")
  unless VD.validCastDescription(desc = req.body.description)
    return next(Err 400, "Invalid Cast Description")

  req.getConnection (err, conn) ->
    return next(err) if err

    sql = '
      start transaction;
      insert into casts (name, description) values (?,?);
      select @last := LAST_INSERT_ID();
      insert into user_casts (user_id, cast_id) values (?,@last);
      commit;'
    conn.query sql, [name, desc, req.user.id], (err) ->
      return next(err) if err
      res.json {}



# @return: [ {id, url, rss, title, rss_type, updated_at} ]
exports.list = (req, res, next) ->
  req.getConnection (err, conn) ->
    return next(err) if err
    sql = "select * from casts as c, user_casts as cs where cs.user_id = ? and cs.cast_id = c.id;"
    conn.query sql, [req.user.id], (err, rows) ->
      return next(err) if err
      res.json rows



exports.del = (req, res, next) ->
  id = parseInt req.params.id
  return next(Err 400, "Invalid id") if isNaN id

  req.getConnection (err, conn) ->
    return next(err) if err

    sql = 'select * from user_casts where user_id = ? and cast_id =?'
    conn.query sql, [req.user.id, id], (err, data) ->
      return next(err) if err
      return next(Err 400, "No permission") unless data

      sql = 'delete from casts where id=?;'
      conn.query sql, [id], (err) ->
        return next(err) if err
        res.json {}


exports.collections = (req, res, next) ->

exports.subscribe = (req, res, next) ->

exports.unsubscribe = (req, res, next) ->

