fs = require 'fs'
path = require 'path'
commander = require 'commander-b'

getVersion = ->
  packageJsonFile = path.join __dirname, '../package.json'
  data = fs.readFileSync packageJsonFile, encoding: 'utf-8'
  packageJson = JSON.parse data
  packageJson.version

action = ->
  console.log 'Hello, MyMyJCB!'

module.exports = ->
  program = commander()
  program.version getVersion()
  program.action action
  program.execute()
