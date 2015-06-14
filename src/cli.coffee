fs = require 'fs'
path = require 'path'
cheerio = require 'cheerio'
commander = require 'commander-b'
moment = require 'moment'
request = require './request'
table = require 'table-b'

getVersion = ->
  packageJsonFile = path.join __dirname, '../package.json'
  data = fs.readFileSync packageJsonFile, encoding: 'utf-8'
  packageJson = JSON.parse data
  packageJson.version

loadCredentials = ({ username, password })->
  # 1. Command-line options
  # 2. Environment Variables
  # 3. The credential file (~/.mymyjcb.json)
  configFile = path.join process.env.HOME, '.mymyjcb.json'
  data = {}
  if fs.existsSync configFile
    data = JSON.parse fs.readFileSync configFile, encoding: 'utf-8'
  data.username = process.env.MYMYJCB_USERNAME if process.env.MYMYJCB_USERNAME?
  data.password = process.env.MYMYJCB_PASSWORD if process.env.MYMYJCB_PASSWORD?
  data.username = username if username?
  data.password = password if password?
  data

parsePage = (res) ->
  $ = cheerio.load res.body
  data = null
  $('select option[selected=selected]').each ->
    e = $ @
    label = e.text()
    amount = $('.amount strong').text()
    match = label.match /^(\d+)年(\d+)月(\d+)日.*?(未?確定).*$/
    year = parseInt match[1], 10
    month = parseInt(match[2], 10) - 1 # Jan is 0
    day = parseInt match[3], 10
    data =
      date: moment({ year, month, day }).format('YYYY-MM-DD')
      fixed: match[4] is '確定'
      amount: parseInt(amount.replace(/[\s,円]/g, ''), 10)
  data

authorize = (cookieStore, username, password) ->
  request
    jar: cookieStore
    method: 'POST'
    url: 'https://my.jcb.co.jp/iss-pc/member/user_manage/Login'
    form:
      userId: username
      password: password
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
    jar: cookieStore
    url: 'https://my.jcb.co.jp/iss-pc/member/details_inquiry/detail.html'
    qs:
      detailMonth: pageNo
      output: 'web'
  .then parsePage

delayedResolve = (value, delay) ->
  new Promise (resolve) ->
    setTimeout ->
      resolve value
    , delay

fetch = (credentials) ->
  # get cookie store
  jar = request.jar()

  Promise.resolve()
  .then ->
    loadCredentials credentials
  .then ({ username, password }) ->
    throw new Error('username is not defined') unless username?
    throw new Error('password is not defined') unless password?
    console.log 'authorize'
    authorize jar, username, password
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
        .then ({ date, fixed, amount } = {}) ->
          result[date] = { date, fixed, amount } if date?
        .then ->
          delayedResolve result, 500
    , Promise.resolve {}
  .then (months) ->
    header = ['date', 'amount', 'fixed']
    values = for _, { date, fixed, amount } of months
      price = amount.toString().replace /(\d)(?=(\d{3})+(?!\d))/g, '$1,'
      [date, price, fixed]
    console.log '\n' # new line
    console.log table [header].concat(values), align: ['l', 'r', 'l']
  .catch (e) ->
    console.error e

module.exports = ->
  program = commander()
  program.version getVersion()
  program.option '--username <username>', 'MyJCB username'
  program.option '--password <password>', 'MyJCB password'
  program.action fetch
  program.execute()
