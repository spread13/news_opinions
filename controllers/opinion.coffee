config = require("../config/config")
Err = require("../lib/err")
VD = require("../lib/validator")

exports.create = (req, res, next) ->
  req.getConnection (err, conn) ->
    return next(err) if err

    sql = 'insert into opinions (user_id, article_id, contents, created_at) values (?,?,?,?);'
    conn.query sql, [req.user.id, req.params.id, req.body.contents, Date.now()], (err) ->
      if err
        return next(err) if err.code != 'ER_DUP_ENTRY'
        conn.query 'delete from opinions where user_id =? and article_id =?',[req.user.id, req.params.id], (err) ->
          return next(err) if err
          res.json {}
      else
      res.json {}

exports.list = (req, res, next) ->
  req.getConnection (err, conn) ->
    return next(err) if err

    userId = req.params.id
    userId = req.user.id if !userId || userId == 'null' || userId == 'undefined'
    ops = 
      sql: 'select * from articles a, opinions o where o.user_id = ? and o.article_id = a.id order by o.updated_at desc;'
      nestTables: true
    conn.query ops, [userId], (err, list) ->
      return next(err) if err
      res.json list.map (x) ->
        x.o.site_id = x.a.site_id
        x.o.article_url = x.a.url
        x.o.article_title= x.a.title
        x.o.article_description = x.a.description
        x.o.article_thumbnail = x.a.thumbnail
        x.o.article_category = x.a.category
        x.o.article_created_at = x.a.created_at
        x.o
