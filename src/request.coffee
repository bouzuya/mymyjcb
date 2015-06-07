{Promise} = require 'es6-promise'
request = require 'request'

module.exports = (params) ->
  new Promise (resolve, reject) ->
    request params, (err, res) ->
      return reject(err) if err?
      resolve res
