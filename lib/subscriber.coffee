fs             = require('fs')
createDomain   = require('domain').create
mysql          = require("mysql")
request        = require("request")
Feedparser     = require("feedparser")
Iconv          = require("iconv").Iconv
Sax            = require("sax")
EventEmitter   = require('events').EventEmitter
_              = require('underscore')
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
  @subscribeInterval: 1000 * 10 

  constructor: (@cell) ->
    @eventEmitter = new EventEmitter()

    self = @
    @eventEmitter.on 'subscribe', -> self.subscribe(self.next.bind(self))
    
    @sweepTempFiles()
    setInterval @sweepTempFiles.bind(@), 10000

  next: (err) ->
    console.trace err if err

  schedule: ->
    self = @
    @subscribe (err) ->
      self.next(err) if err
      setTimeout self.schedule.bind(self), Subscriber.scheduleInterval

  sweepTempFiles: ->
    console.log 'sweep'
    fs.readdir '/tmp', (err, files) ->
      return next(err) if err
      for f in files
        created = parseInt(f)
        continue if isNaN created
        fs.unlink("/tmp/#{f}") if Date.now() > created + 3*60000

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
    console.log "r: #{url}"
    req = request(url)
    feedparser = new Feedparser()

    self = @
    req.setMaxListeners 50
    req.setHeader 'user-agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36'
    req.setHeader 'accept', 'text/html,text/xml,application/xhtml+xml,application/rss+xml'
    req.on 'error', self.next

    req.on 'response', (res) ->
      stream = @
      return cb(new Error "Invalid rss url: #{[site_id, url]} cause #{res.statusCode}") if res.statusCode != 200

      charset = self._getParams(res.headers['content-type'] || '').charset
      done = (stream) ->
        if !/utf-*8/i.test(charset)
          try
            iconv = new Iconv charset, 'utf-8'
            iconv.on 'error', self.next
            stream = stream.pipe iconv
          catch err
            return cb(err)
        stream.pipe feedparser        

      unless charset
        tmpfile = "/tmp/#{Date.now()}"
        ws = fs.createWriteStream(tmpfile)
        stream.pipe ws

        sax = Sax.createStream()
        sax.on 'error', self.next
        sax.on 'processinginstruction', (xml) ->
          charset = self._getEncodingFromXmlInst(xml.body)
        sax.on 'end', ->
          rs = fs.createReadStream(tmpfile)
          done(rs)
          
        stream = stream.pipe sax
      else done(stream)

    posts = []
    feedparser.on 'error', self.next
    feedparser.on 'end', (err) ->
      return cb(err) if err
      self.pushArticle conn, site_id, posts, (err) ->
        return cb(err) if err
        self.updateSubscribedTime conn, site_id, cb
    feedparser.on 'readable', ->
      while post = @read()
        posts.push post

  updateSubscribedTime: (conn, site_id, cb) ->
    sql = 'update sites set subscribed_at = ? where id = ?;'
    conn.query sql, [Date.now(), site_id], cb

  pushArticle: (conn, site_id, posts, cb) ->
    params =[]
    for p in posts
      continue unless p.title && (p.description || p.summary) && p.link
      created_at = new Date(p.pubdate)
      created_at = new Date() if isNaN(created_at)
      
      params.push [site_id, p.link, p.title, (p.description || p.summary), p.image?.url || null, p?.categories.join(',') || null, created_at, new Date()]

    return cb() if params.length == 0

    sql = "insert ignore into articles (site_id, url, title, description, thumbnail, category, created_at, added_at) values #{params.map((p) -> '(?)').join(',')};"
    console.log "pushed #{params.length}"
    conn.query sql, params, cb

  _getEncodingFromXmlInst: (s) ->
    s = s.match(/encoding\w*=\".+\"/g)
    return null if s.length == 0
    s[0].substring(s[0].indexOf('=')+1).replace(/\"/g,'')
      
  _getParams: (s) ->
    res = {}
    s.split(';').forEach (param) ->
      parts = param.split('=').map (part) -> part.trim()  
      res[parts[0]] = parts[1] if parts.length == 2 
    res
     
module.exports = Subscriber

