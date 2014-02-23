config = require("../config/config")
Err = require("../lib/err")
VD = require("../lib/validator")

# url, rss, title
exports.create = (req, res, next) ->
  unless VD.validUrl(url = req.body.url)
    return next(Err 400, "Invalid URL")
  unless VD.validRss(rss = req.body.rss)
    return next(Err 400, "Invalid RSS")
  unless VD.validTitle(title = req.body.title)
    return next(Err 400, "Invalid Title")

  url = url && VD.toSqlSafe(url) || null
  title = title && VD.toSqlSafe(title) || null
  rss = VD.toSqlSafe(rss)
  sql = '
    start transaction;
    insert into sites (url, rss, title, rss_type) values (?,?,?,?) on duplicate key update rss_type = ?;
    select @last := LAST_INSERT_ID();
    insert into user_sites (user_id, site_id, credentials) values (?,@last,?);
    commit; '
  req.getConnection (err, conn) ->
    return next(err) if err

    conn.query sql, [url, rss, title, 0, 0, req.user.id, null], (err) ->
      return next(err) if err
      res.json {}


# arrays of id, url, rss, title, rss_type, credentials, updated_at
exports.list = (req, res, next) ->
  req.getConnection (err, conn) ->
    return next(err) if err
    conn.query "select * from sites as s, user_sites as us where us.user_id = ?;", [req.user.id], (err, rows) ->
      return next(err) if err

      res.json rows.map (r) ->
        id: r.id
        url: r.url
        rss: r.rss
        title: r.title
        rss_type: r.rss_type
        credentials: r.credentials
        updated_at: r.updated_at.getTime()


exports.del = (req, res, next) ->
  id = parseInt req.params.id
  return next(Err 400, "Invalid id") if isNaN id

  req.getConnection (err, conn) ->
    return next(err) if err
    sql = '
      start transaction;
      select count(*) from user_sites where site_id=? into @n;
      update sites set rss_type = 2 where id = ? and rss_type=1 and @n =1;
      delete from user_sites where user_id=? and site_id=?;
      commit; '
    conn.query sql, [id, id, req.user.id, id], (err) ->
      return next(err) if err
      res.json {}


