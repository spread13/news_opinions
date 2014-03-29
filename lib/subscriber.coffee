fs             = require('fs')
url            = require('url')
createDomain   = require('domain').create
mysql          = require("mysql")
request        = require("request")
htmlparser     = require("htmlparser2")
Iconv          = require("iconv").Iconv
EventEmitter   = require('events').EventEmitter
_              = require('underscore')
Boilerpipe     = require('boilerpipe')
cheerio        = require('cheerio')
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

    sql = 'select * from sites where subscribed_at < ? order by subscribed_at asc limit 2;'
    #sql = 'select * from sites;'
    conn.query sql, [Date.now() - Subscriber.subscribeInterval], (err, sites) ->
      return cb(err) if err

      expected = 1
      err = null
      done = (_err) ->
        err = _err if _err
        return if --expected > 0
        cb err

      for site in sites
        expected++
        self._request conn, site.id, site.url, done
      done()  

  normalizeUrl: (u) ->
    parsed = url.parse(u)
    unless parsed.host
      parsed = url.parse "http://#{parsed.href}"
    parsed.host && parsed.href || null

  _request: (conn, site_id, siteurl, cb) ->
    site_url = @normalizeUrl(siteurl)
    console.log "r: #{site_url}"
    return cb("Invalid url: #{siteurl}") unless site_url
    req = request(site_url)

    self = @
    req.setMaxListeners 50
    req.setHeader 'user-agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.63 Safari/537.36'
    req.setHeader 'accept', 'text/html,text/xml,application/xhtml+xml,application/rss+xml'
    req.on 'error', self.next

    req.on 'response', (res) ->
      stream = @
      return cb(new Error "Invalid rss url: #{[site_id, site_url]} cause #{res.statusCode}") if res.statusCode != 200

      charset = self._getParams(res.headers['content-type'] || '').charset

      links = []
      parser = new htmlparser.Stream()
      parser.on 'opentag', (name, attrs) ->
        links.push attrs.href if name == 'a' && attrs.href
      parser.on 'end', -> 
        filtered = self.filterExLinks(site_url, links)
        self.extractSites filtered, (err, contents) ->
          return cb(err) if err
          self.pushArticle conn, site_id, contents, (err) ->
            return cb(err) if err
            self.updateSubscribedTime conn, site_id, cb
      stream.pipe parser

  extractSites: (urls, cb) ->
    contents = {}

    expected = urls.length
    done = (_err) ->
      #console.log _err if _err
      return if --expected > 0
      cb null, contents

    for u in urls
      @extractSite u, (err, content) ->
        contents[content.url] = content if content
        done(err)

  extractSite: (site_url, cb) ->
    console.log 'extract: '+ site_url
    bp = new Boilerpipe
      extractor: Boilerpipe.Extractor.ArticleSentences
      url: site_url

    bp.getText (err, text) ->
      return cb(err) if err
      data = if text?.length > 0
        url: site_url
        title: text.substring(0, _.min([text.length,30]))
        summary: text.substring(0, _.min([text.length,300]))
        thumbnail: null
        date: new Date()
      else null
      cb null, data
    #bp.getHtml (err, html) -> 
    #bp.getImages (err, images) -> 

  extractSite2: (site_url, cb) ->
    console.log 'extract: '+ site_url
    request site_url, (err, res, body) ->
      return cb(err) if err
      $ = cheerio.load(body)

      data =
        url: site_url
        title: $('title').text()
        summary: $('title').text()
        thumbnail: null
        date: new Date()
      cb null, data
    

  filterLinks: (site_url, links) ->
    candis = {}
    site = url.parse site_url
    for l in links
      target = url.parse l
      if (!target.host || site.host == target.host) && target.pathname
        candi = candis[target.pathname] ||= {}
        candi[target.path] = target.path

    selected = {}
    selLen = 0
    for pathname, paths of candis
      if (len = Object.keys(paths).length) >= selLen
        selected = paths
        selLen = len

    if selLen <= 1
      return @filterExLinks(site_url, links)

    base = "#{site.protocol || 'http:'}//#{site.host}"
    Object.keys(selected).map (x) -> url.resolve base, x


  filterExLinks: (site_url, links) ->
    candis = {}
    site = url.parse site_url
    base = "#{site.protocol || 'http:'}//#{site.host}"
    domain = @extractDomain(site.host)
    for l in links
      target = url.parse l
      host = target.host || site.host
      if host.indexOf(domain) >= 0 && target.path?.length > 1
          candi = candis[host+target.pathname] ||= {}
          href = target.host && target.href || url.resolve(base, target.href)
          candi[href] = href

    selected = {}
    selLen = 0
    for key, hrefs of candis
      list = Object.keys hrefs
      if (len = list.length) >= selLen
        console.log [key, len]
        selected = list
        selLen = len

    selected

  extractDomain: (host) ->
    parts = host.split('.')
    len = parts.length
    return host if len <= 2
    if ['co', 'pe'].indexOf(parts[len-2]) >= 0
      parts[len-3...len].join('.')
    else
      parts[len-2...len].join('.')

  updateSubscribedTime: (conn, site_id, cb) ->
    sql = 'update sites set subscribed_at = ? where id = ?;'
    conn.query sql, [Date.now(), site_id], cb

  pushArticle: (conn, site_id, contents, cb) ->
    params =[]
    for _url, data of contents
      params.push [site_id, _url, data.title, data.summary, data.thumbnail, data.date, new Date()]

    return cb() if params.length == 0

    sql = "insert ignore into articles (site_id, url, title, description, thumbnail, created_at, added_at) values #{params.map((p) -> '(?)').join(',')};"
    console.log "pushed #{params.length}"
    conn.query sql, params, cb


  _getEncodingFromXmlInst: (s) ->
    s = s.match(/encoding\w*=\".+\"/g)
    return null if !s || s.length == 0
    s[0].substring(s[0].indexOf('=')+1).replace(/\"/g,'')
      
  _getParams: (s) ->
    res = {}
    s.split(';').forEach (param) ->
      parts = param.split('=').map (part) -> part.trim()  
      res[parts[0]] = parts[1] if parts.length == 2 
    res
     
module.exports = Subscriber

