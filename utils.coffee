shell = require('shelljs')
fs = require('fs-extra-promise')

shell.config.silent = true

module.exports.writeConf = (path, model) ->
  return fs.writeJSONAsync(path, model, {spaces: 2})

module.exports.gitTags = ->
  out = shell.exec('git tag').output.trim()
  return out
