fs = require 'fs'
path = require 'path'
cheerio = require 'cheerio'
commander = require 'commander-b'
request = require './request'

getVersion = ->
  packageJsonFile = path.join __dirname, '../package.json'
  data = fs.readFileSync packageJsonFile, encoding: 'utf-8'
  packageJson = JSON.parse data
  packageJson.version

authorize = (cookieStore) ->
  request
    jar: cookieStore
    method: 'POST'
    url: 'https://my.jcb.co.jp/iss-pc/member/user_manage/Login'
    form:
      userId: process.env.MYMYJCB_USERNAME
      password: process.env.MYMYJCB_PASSWORD
      # 'login.x': '131'
      # 'login.y': '43'
      screenId: '0102001'
      loginRouteId: '0102001'

fetchForCookie = (cookieStore) ->
  request
    jar: cookieStore
    url: 'https://my.jcb.co.jp/iss-pc/member/details_inquiry/detail.html'
    qs:
      detailMonth: 1
      output: 'web'

fetchForPage = (cookieStore, pageNo) ->
  throw new Error("invalid pageNo: #{pageNo}") if pageNo < 0 or 6 < pageNo
  request
    jar: jar
    url: 'https://my.jcb.co.jp/iss-pc/member/details_inquiry/detail.html'
    qs:
      detailMonth: pageNo
      output: 'web'
  .then (res) ->
    $ = cheerio.load res.body
    data = null
    $('select option[selected=selected]').each ->
      e = $ @
      data =
        label: e.text()
        amount: $('.amount strong').text()
    data

delayedResolve = (value, delay) ->
  new Promise (resolve) ->
    setTimeout ->
      resolve value
    , delay

fetch = ->
  # get cookie store
  jar = request.jar()

  Promise.resolve()
  .then ->
    console.log 'authorize'
    authorize jar
  .then ->
    console.log 'fetch cookie'
    fetchForCookie jar
  .then ->
    console.log 'fetch [0..6]'
    [0..6].reduce (promise, i) ->
      promise
      .then (result) ->
        console.log("fetch [#{i}]")
        fetchForPage jar, i
        .then ({ label, amount } = {}) ->
          result[label] = amount if label?
        .then ->
          deleyedResolve result, 500
    , Promise.resolve {}
  .then (months) ->
    console.log months
  .catch (e) ->
    console.error e

action = ->
  fetch()

module.exports = ->
  program = commander()
  program.version getVersion()
  program.action action
  program.execute()
