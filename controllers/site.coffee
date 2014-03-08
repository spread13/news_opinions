config = require("../config/config")
Err = require("../lib/err")
VD = require("../lib/validator")

# url, rss, title
exports.create = (req, res, next) ->
  unless VD.validUrl(url = req.body.url)
    return next(Err 400, "Invalid URL")
  if (rss = req.body.rss) && !VD.validRss(req.body.rss)
    return next(Err 400, "Invalid RSS")
  if (title = req.body.title) && !VD.validTitle(req.body.title)
    return next(Err 400, "Invalid Title")

  req.getConnection (err, conn) ->
    return next(err) if err

    sql = if rss
      'select id from sites where rss = ?'
    else
      'select id from sites where url = ?'
    conn.query sql, [rss || url], (err, sites) ->
      return next(err) if err

      if sites.length > 0
        sql = 'insert ignore into user_sites (user_id, site_id, title) values (?,?,?);'
        conn.query sql, [req.user.id, sites[0].id, title], (err) ->
          return next(err) if err
          res.json {}
      else
        sql = '
          start transaction;
          insert into sites (url, rss) values (?,?);
          select @last := LAST_INSERT_ID();
          insert into user_sites (user_id, site_id, title) values (?,@last,?);
          commit;'
        conn.query sql, [url, rss, req.user.id, title], (err) ->
          return next(err) if err
          res.json {}

# arrays of id, url, rss, title, rss_type, updated_at
exports.list = (req, res, next) ->
  req.getConnection (err, conn) ->
    return next(err) if err
    conn.query "select * from sites as s, user_sites as us where us.user_id = ? and us.site_id = s.id;", [req.user.id], (err, rows) ->
      return next(err) if err

      res.json rows.map (r) ->
        id: r.id
        url: r.url
        rss: r.rss
        title: r.title
        subscribed_at: r.subscribed_at.getTime()

exports.del = (req, res, next) ->
  id = parseInt req.params.id
  return next(Err 400, "Invalid id") if isNaN id

  req.getConnection (err, conn) ->
    return next(err) if err
    sql = 'delete from user_sites where user_id=? and site_id=?;'
    conn.query sql, [req.user.id, id], (err) ->
      return next(err) if err
      res.json {}

exports.myArticles = (req, res, next) ->
  req.getConnection (err, conn) ->
    return next(err) if err

    sql = 'select site_id from user_sites where user_id = ?;'
    conn.query sql, [req.user.id], (err, sites) ->
      return next(err) if err
      return next(Err 404, "No registered sites") if sites.length == 0

      site_ids = sites.map (x) -> x.site_id
      sql = 'select * from articles where site_id in (??) order by created_at desc limit 50'
      conn.query sql, site_ids, (err, articles) ->
        return next(err) if err
        res.json articles

exports.articles = (req, res, next) ->
  id = parseInt req.params.id
  return next(Err 400, "Invalid id") if isNaN id
  res.json {}
