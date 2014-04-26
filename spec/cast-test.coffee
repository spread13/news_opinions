_   = require 'underscore'
Sync = require 'sync'
req = require 'supertest'
req = req 'localhost:3333'
hh = require './helper'

user0 =
  name: 'asdf'
  email: 'asdf@asdf.com'
  pwd: 'asdf00'

user1 =
  name: 'asdf1'
  email: 'asdf1@asdf.com'
  pwd: 'asdf01'

log = (res) ->
  console.log """
    ### #{res.req.method} #{res.req.path} ###
    status: #{res.status}
    header: #{JSON.stringify res.header}
    body: #{JSON.stringify res.body}
    text: #{res.text}\n
  """

Sync ->
  try
    token = hh.createUser.sync null, user0, name: 'user0'
    token2 = hh.createUser.sync null, user1, name: 'user1'

    hh.createCast.sync null, token, {name: 'testcast', description: 'from test case'}
    list = hh.listCasts.sync null, token
    throw "fail to create cast" if list.length == 0
    castId = list[0].id

    hh.createPaper.sync null, token, castId, name: '1호'
    list = hh.listPapers.sync null, token, castId
    throw "fail to create paper" if list.length == 0
    paperId = list[0].id

    hh.createArticle.sync null, token, paperId, title: '세월호', url: 'www.naver.com'
    list = hh.listArticles.sync null, token, paperId
    throw "fail to create article" if list.length == 0
    articleId = list[0].id

    hh.delArticle.sync null, token, articleId
    list = hh.listArticles.sync null, token, paperId
    throw "fail to delete article" if list.length > 0

    hh.delPaper.sync null, token, paperId
    list = hh.listPapers.sync null, token, castId
    throw "fail to delete paper" if list.length > 0

    hh.delCast.sync null, token, castId

  catch e
    console.error e

  hh.delUser.sync null, user0
  hh.delUser.sync null, user1

