shell = require('shelljs')
fs = require('fs-extra-promise')
prettyjson = require('prettyjson')

shell.config.silent = true

module.exports.writeConf = (path, model) ->
  return fs.writeJSONAsync(path, model, {spaces: 2})

module.exports.gitTags = ->
  out = shell.exec('git tag').output.trim()
  return out

module.exports.repo = ->
  out = shell.grep('Vcs-Git', process.cwd() + '/debian/control')
  return out.split(' ')[1].trim()

module.exports.cloneRepo = (url, dst) ->
  shell.exec("git clone #{url} #{dst}")

module.exports.pj = (model) ->
  console.log(prettyjson.render(model, {
    keysColor: 'grey'
    dashColor: 'red'
    stringColor: 'white'
    numberColor: 'magenta'
  }))
