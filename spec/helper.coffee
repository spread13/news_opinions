_   = require 'underscore'
req = require 'supertest'
req = req 'localhost:3333'


log = (res) ->
  console.log """
    ### #{res.req.method} #{res.req.path} ###
    status: #{res.status}
    header: #{JSON.stringify res.header}
    body: #{JSON.stringify res.body}
    text: #{res.text}\n
  """
module.exports.log = log

module.exports.delUser = (user, cb) ->
  req.post('/login')
    .send(user)
    .set('Accept', 'application/json')
    .end (err, res) ->
      return cb(err || res.body) if err || res.status >= 400
      
      token = res.body.token.id
      req.put("/me/del")
        .send(user)
        .set('Accept', 'application/json')
        .set('Authorization', token)
        .end cb

module.exports.createUser = (user, userInfo, cb) ->
  req.post('/users')
    .send(user)
    .set('Accept', 'application/json')
    .expect(200)
    .end (err, res) ->
      return cb(err) if err

      req.post('/login')
        .send(user)
        .set('Accept', 'application/json')
        .expect(201)
        .end (err, res) ->
          return cb(err) if err

          token = res.body.token.id
          req.put("/me")
            .send(userInfo)
            .set('Accept', 'application/json')
            .set('Authorization', token)
            .expect(201)
            .end (err, res) -> cb err, res?.body.token.id

module.exports.createCast = (token, data, expected, cb) ->
  [expected, cb] = [200, expected] unless cb

  req.post("/casts")
    .send(data)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(expected)
    .end (err, res) ->
      log res if res
      cb err, res?.body
 
module.exports.listCasts = (token, expected, cb) ->
  [expected, cb] = [200, expected] unless cb

  req.get("/casts")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(expected)
    .end (err, res) ->
      log res if res
      cb err, res?.body
 
module.exports.delCast = (token, id, expected, cb) ->
  [expected, cb] = [200, expected] unless cb

  req.del("/casts/#{id}")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(expected)
    .end (err, res) ->
      log res if res
      cb err, res?.body
 

module.exports.createPaper = (token, castId, data, expected, cb) ->
  [expected, cb] = [200, expected] unless cb

  req.post("/casts/#{castId}/papers")
    .send(data)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(expected)
    .end (err, res) ->
      log res if res
      cb err, res?.body
 
module.exports.listPapers = (token, castId, expected, cb) ->
  [expected, cb] = [200, expected] unless cb

  req.get("/casts/#{castId}/papers")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(expected)
    .end (err, res) ->
      log res if res
      cb err, res?.body
 
module.exports.delPaper = (token, paperId, expected, cb) ->
  [expected, cb] = [200, expected] unless cb

  req.del("/papers/#{paperId}")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(expected)
    .end (err, res) ->
      log res if res
      cb err, res?.body
 

module.exports.createArticle = (token, paperId, data, expected, cb) ->
  [expected, cb] = [200, expected] unless cb

  req.post("/papers/#{paperId}/articles")
    .send(data)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(expected)
    .end (err, res) ->
      log res if res
      cb err, res?.body
 
module.exports.listArticles = (token, paperId, expected, cb) ->
  [expected, cb] = [200, expected] unless cb

  req.get("/papers/#{paperId}/articles")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(expected)
    .end (err, res) ->
      log res if res
      cb err, res?.body
 
module.exports.delArticle = (token, articleId, expected, cb) ->
  [expected, cb] = [200, expected] unless cb

  req.del("/articles/#{articleId}")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(expected)
    .end (err, res) ->
      log res if res
      cb err, res?.body
 

## reference ##

module.exports.status = (token, cb) ->
  req.get('/status')
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err, res?.body

module.exports.post = (token, body, cate, buddies, status, cb) ->
  data = {}
  data.body = body
  data.cate = cate if cate
  data.buddies = buddies if buddies
  status ||= 200

  req.post("/feeds")
    .send(data)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(status)
    .end (err, res) ->
      log res if res
      cb err, res?.body
 

module.exports.postWithCateName = (token, cateName, body, cb) ->
  req.post("/feeds")
    .send(cate: cateName, body: body)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err, res?.body
  
module.exports.pick = (token, cb) ->
  req.get("/feeds/pick")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err, res?.body

module.exports.feeds = (token, cb) ->
  req.get("/feeds")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err, res?.body

module.exports.commentTo = (token, postId, body, cb) ->
   req.post("/feeds/#{postId}/comments")
    .send(body: body)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err

module.exports.comment = (token, postId, body, buddies, status, cb) ->
   data = {}
   data.body = body
   data.buddies = buddies if buddies
   status ||= 200

   req.post("/feeds/#{postId}/comments")
    .send(data)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(status)
    .end (err, res) ->
      log res if res
      cb err


module.exports.myCategories = (token, cb) ->
  req.get("/me/categories")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err, res?.body

module.exports.search = (token, cate, cb) ->
  req.get("/search")
    .query(cate: cate)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err, res?.body

module.exports.addBuddy = (token, buddy, cb) ->
  req.post("/buddies")
    .send(name: buddy)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err

module.exports.buddies = (token, cb) ->
  req.get("/buddies")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err, res?.body

module.exports.delBuddy = (token, buddy, cb) ->
  req.del("/buddies/#{buddy}")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err
 

module.exports.postToBuddies = (token, buddies, body, cb) ->
  req.post("/feeds")
    .send(body: body, buddies: buddies)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err, res?.body

module.exports.leavePost = (token, feedId, cb) ->
  req.del("/feeds/#{feedId}")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err

module.exports.invite = (token, postId, buddies, cb) ->
  req.post("/feeds/#{postId}/invite")
    .send(buddies: buddies)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err

module.exports.resetAccount = (email, cb) ->
  req.put("/me/reset")
    .send(email: email)
    .set('Accept', 'application/json')
    .expect(200)
    .end (err, res) ->
      log res if res
      cb err


