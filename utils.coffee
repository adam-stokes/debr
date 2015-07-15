Promise = require('bluebird')
shell = require('shelljs')
fs = require('fs-extra-promise')
isFile = require('is-file')
prettyjson = require('prettyjson')

shell.config.silent = true

class Utils
  constructor: ->
  writeConf: (path, model) ->
    return fs.outputJsonSync(path, model, {spaces: 2})

  gitTags: ->
    out = shell.exec('git tag').output.trim()
    return Promise.resolve(out)

  repo: ->
    out = shell.grep('Vcs-Git', process.cwd() + '/debian/control')
    return out.split(' ')[1].trim()

  cloneRepo: (url, dst) ->
    console.log "Cloning: #{url}"
    shell.exec("git clone #{url} #{dst}")
    shell.cd(dst)
    if isFile("#{dst}/.gitmodules")
      console.log "Cloning: Found submodules, updating."
      shell.exec("git submodule init")
      shell.exec("git submodule update")

  pj: (model) ->
    console.log(prettyjson.render(model, {
      keysColor: 'grey'
      dashColor: 'red'
      stringColor: 'white'
      numberColor: 'magenta'
    }))

module.exports = new Utils()
