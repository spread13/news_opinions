config = require("../config/config")
Err = require("../lib/err")
VD = require("../lib/validator")


exports.create = (req, res, next) ->
  paperId = parseInt req.params.id
  return next(Err 400, "Invalid id") if isNaN paperId
  unless VD.validArticleTitle(title = req.body.title)
    return next(Err 400, "Invalid Article Title")
  unless VD.validURL(url = req.body.url)
    return next(Err 400, "Invalid Article URL")

  req.getConnection (err, conn) ->
    return next(err) if err

    sql = 'insert into articles (paper_id, title, url) values (?,?,?);'
    conn.query sql, [paperId, title, url], (err) ->
      return next(err) if err
      res.json {}


exports.list = (req, res, next) ->
  paperId = parseInt req.params.id
  return next(Err 400, "Invalid id") if isNaN paperId

  req.getConnection (err, conn) ->
    return next(err) if err

    sql = "select * from articles where paper_id = ?;"
    conn.query sql, [paperId], (err, rows) ->
      return next(err) if err
      res.json rows



exports.del = (req, res, next) ->
  articleId = parseInt req.params.id
  return next(Err 400, "Invalid id") if isNaN articleId

  req.getConnection (err, conn) ->
    return next(err) if err

    sql = 'select * from user_casts as uc, papers as p, articles as a where a.id = ? and p.id = a.paper_id and p.cast_id = uc.cast_id and uc.user_id = ?;'
    conn.query sql, [articleId, req.user.id], (err, data) ->
      return next(err) if err
      return next(Err 400, "No permission") unless data

      sql = 'delete from articles where id=?;'
      conn.query sql, [articleId], (err) ->
        return next(err) if err
        res.json {}


