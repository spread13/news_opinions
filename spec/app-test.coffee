req = require 'supertest'
req = req 'localhost:3333'

testuser =
  email: 'asdf@asdf.com'
  password: 'asdf00'

testuserInfo =
  email: 'qwer@asdf.com'
  name: 'asdf2'
  password: 'asdf00'


log = (res) ->
  console.log """
    ### #{res.req.method} #{res.req.path} ###
    status: #{res.status}
    header: #{JSON.stringify res.header}
    body: #{JSON.stringify res.body}
    text: #{res.text}\n
  """

next = (fn) -> 
  (err, res) ->
    if err
      console.log(err?.stack || err)
      return done()
    log res if res
    fn(res)

done = ->
  expected = 2
  _last = (err) ->
    return if --expected > 0
    console.log err || ':)'

  delUser testuser, _last
  delUser testuserInfo, _last

delUser = (user, cb) ->
  req.post('/login')
    .send(user)
    .set('Accept', 'application/json')
    .end (err, res) ->
      return cb(err || res.body) if err || res.status >= 400
      
      token = res.body.token.id
      req.del("/me")
        .set('Accept', 'application/json')
        .set('Authorization', token)
        .end cb

createUser = (user, cb) ->
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
        .end cb


token = token2 = null
_0 = ->
  expected = 1
  _err = null
  _done = (err, res) ->
    _err = err
    return if --expected > 0
    next(_4)(_err)

  createUser testuser, (err, res) ->
    token = res.body.token.id if res
    _done(err, res)


_4 = (res) ->
  req.get("/me")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end next(_5)

_5 = (res) ->
  req.put("/me")
    .send(testuserInfo)
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(201)
    .end next(_6)

_6 = (res) ->
  req.del("/me")
    .set('Accept', 'application/json')
    .set('Authorization', token)
    .expect(200)
    .end next(done)


_0()
