createDomain   = require('domain').create
mysql          = require("mysql")
request        = require("request")
Feedparser     = require("feedparser")
Iconv          = require("iconv").Iconv
EventEmitter   = require('events').EventEmitter
config         = require '../config/config'
secrets        = require '../config/secrets'


pool = mysql.createPool
  multipleStatements: true
  debug: false
  host: secrets.mysql.host
  port: secrets.mysql.port
  user: secrets.mysql.user
  password: secrets.mysql.password
  database: secrets.mysql.database


class Subscriber
  @scheduleInterval: 10000
  @subscribeInterval: 1000 * 60 

  constructor: (@cell) ->
    @eventEmitter = new EventEmitter()

    self = @
    @eventEmitter.on 'subscribe', -> self.subscribe(self.next.bind(self))

  next: (err) ->
    console.log err.stack if err

  schedule: ->
    self = @
    @subscribe (err) ->
      self.next(err) if err
      setTimeout self.schedule.bind(self), Subscriber.scheduleInterval

  subscribe: (cb) ->
    self = @
    domain = createDomain()
    domain.on 'error', @next.bind(@)
    domain.run ->
      pool.getConnection (err, conn) ->
        return cb(err) if err
        self._subscribe(conn, cb)
        conn.release()

  _subscribe: (conn, cb) ->
    console.log 's'
    self = @

    sql = 'select * from sites where rss is not null and subscribed_at < ? order by subscribed_at asc limit 50;'
    conn.query sql, [Date.now() - Subscriber.subscribeInterval], (err, sites) ->
      return cb(err) if err

      expected = 1
      err = null
      done = (_err) ->
        err = _err if _err
        return if --expected > 0
        cb err

      for site in sites
        if site.rss
          expected++
          self._request conn, site.id, site.rss, done
      done()  

  _request: (conn, site_id, url, cb) ->
    console.log 'r'
    req = request(url)
    feedparser = new Feedparser()

    self = @
    req.setMaxListeners 50
    req.setHeader 'user-agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36'
    req.setHeader 'accept', 'text/html,application/xhtml+xml'
    req.on 'error', self.next

    req.on 'response', (res) ->
      stream = @
      return cb(res.statusCode) if res.statusCode != 200

      charset = self._getParams(res.headers['content-type'] || '').charset
      if charset && !/utf-*8/i.test(charset)
        try
          iconv = new Iconv charset, 'utf-8'
          iconv.on 'error', self.next
          stream = stream.pipe iconv
        catch err
          return cb(err)
      stream.pipe feedparser        

    posts = []
    feedparser.on 'error', self.next
    feedparser.on 'end', (err) ->
      return cb(err) if err
      self.pushArticle conn, posts, (err) ->
        return cb(err) if err
        self.updateSubscribedTime conn, site_id, cb
    feedparser.on 'readable', ->
        while post = @read()
          posts.push post

  updateSubscribedTime: (conn, site_id, cb) ->
    sql = 'update sites set subscribed_at = ? where id = ?;'
    conn.query sql, [Date.now(), site_id], cb

  pushArticle: (conn, posts, cb) ->
    params =[]
    for p in posts
      continue unless p.title && (p.description || p.summary) && p.link
      created_at = new Date(p.pubdate)
      created_at = new Date() if isNaN(created_at)
      
      params.push [p.link, p.title, p.description || p.summary, p.image?.url || null, p?.categories.join(',') || null, created_at]

    return cb() if params.length == 0

    sql = "insert ignore into articles (url, title, description, thumbnail, category, created_at) values #{params.map((p) -> '(?)').join(',')};"
    console.log "pushed #{params.length}"
    conn.query sql, params, cb
      
  _getParams: (s) ->
    res = {}
    s.split(';').forEach (param) ->
      parts = param.split('=').map (part) -> part.trim()  
      res[parts[0]] = parts[1] if parts.length == 2 
    res
     
module.exports = Subscriber

