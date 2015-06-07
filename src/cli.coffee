fs = require 'fs'
path = require 'path'
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

fetch = ->
  # get cookie store
  jar = request.jar()

  Promise.resolve()
  .then ->
    console.log 'authorize'
    authorize jar
  .catch (e) ->
    console.error e

action = ->
  fetch()

module.exports = ->
  program = commander()
  program.version getVersion()
  program.action action
  program.execute()
