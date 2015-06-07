{Promise} = require 'es6-promise'
request = require 'request'
{Iconv} = require 'iconv'

promisedRequest = (params) ->
  new Promise (resolve, reject) ->
    request params, (err, res) ->
      return reject(err) if err?
      resolve res

module.exports = (params) ->
  params.encoding = 'binary'
  promisedRequest params
  .then (res) ->
    iconv = new Iconv 'CP932', 'UTF-8//TRANSLIT//IGNORE'
    body = new Buffer res.body, 'binary'
    res.body = iconv.convert(body).toString()
    res

module.exports.jar = request.jar.bind request
