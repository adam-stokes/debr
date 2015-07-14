Promise = require('bluebird')
shell = require('shelljs')
fs = require('fs-extra-promise')
prettyjson = require('prettyjson')

shell.config.silent = true

class Utils
  constructor: ->
  writeConf: (path, model) ->
    return fs.writeJSONAsync(path, model, {spaces: 2})

  gitTags: ->
    out = shell.exec('git tag').output.trim()
    return Promise.resolve(out)

  repo: ->
    out = shell.grep('Vcs-Git', process.cwd() + '/debian/control')
    return out.split(' ')[1].trim()

  cloneRepo: (url, dst) ->
    console.log "Cloning: #{url}"
    shell.exec("git clone #{url} #{dst}")

  pj: (model) ->
    console.log(prettyjson.render(model, {
      keysColor: 'grey'
      dashColor: 'red'
      stringColor: 'white'
      numberColor: 'magenta'
    }))

module.exports = new Utils()
