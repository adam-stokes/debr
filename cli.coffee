#!/usr/bin/env coffee
Promise = require('bluebird')
program = require('commander')
fs = require('fs-extra-promise')
isFile = Promise.promisify(require('is-file'))
prettyjson = require('prettyjson')
_ = require('lodash')
pkgInfo = require('./package.json')
ChangeLog = require('.')
require('shelljs/global')

debrInfoPath = process.cwd() + '/debr.json'
debChangeLogPath = process.cwd() + '/debian/changelog'

program
  .version("debr v#{pkgInfo.version}")

program
  .command('init')
  .description('Initialize a debr project')
  .action ->
    console.log 'initializing'
program
  .command('build')
  .description('Build a debian package from current version')
  .action ->
    console.log 'building'
program
  .command('changelog')
  .description('Parse existing debian/changelog')
  .action ->
    ChangeLog.parse(debChangeLogPath)
      .then((cl) ->
        for entry in cl.splitLogs()
          console.log(prettyjson.render(cl.parse(entry)))
        return)
      .catch((e) ->
        console.error e
        return process.exit 1)
program
  .command('config')
  .description('Displays current debr configuration')
  .action ->
    console.log(prettyjson.render(debrInfo, {
      keysColor: 'grey'
      dashColor: 'red'
    }))
program
  .command('config-set "<key>=<val>"')
  .description('Sets config option, ie config-set "series.wily=15.10"')
  .action (conf) ->
    [confKey, confVal] = conf.trim().split('=')
    unless confKey? and confVal?
      console.error "Invalid key=val format."
      process.exit 1
    _.set(debrInfo, confKey, confVal)
    fs.writeJSONAsync(debrInfoPath, debrInfo, {spaces: 2})
      .then(->
        console.log "Saved '#{confKey}=#{confVal}' to config"
        return)
      .catch((e) -> console.error "Problem saving config: #{e}")
program
  .command('config-get "<key>"')
  .description('Gets config option, ie config-get "releases[0].tag"')
  .action (confKey) ->
    fs.readJSONAsync(debrInfoPath)
      .then((debrParse)->
        console.log _.get(debrParse, confKey) ? "Key: #{confKey} not found."
        return)
      .catch((e) -> console.error "Problem reading config: #{e}")
program
  .command('series')
  .description('List current registered series')
  .action ->
    console.log "Currently registered series:"
    keys = _.sortBy(_.keys(debrInfo.series), (a) -> return a)
    _.each(keys, (k) ->
      console.log _.padLeft("#{k} (#{debrInfo.series[k]})", 20))
program
  .command('new-release')
  .description('Tags, Changes, Builds, and Commit pkg to git.')
  .action ->
    console.log 'new release'
program
  .command('new-series <series> <version>')
  .description('Register a new series')
  .action (series, version) ->
    console.log "Registering series: #{series} (#{version})"
    debrInfo['series'][series] = version
    console.log debrInfo['series']
    fs.writeJSONAsync(debrInfoPath, debrInfo, {spaces: 2})
      .then(->
        console.log "Saved debr.json"
        return)
      .catch((e) -> console.error "Problem saving config: #{e}")
program
  .command('tag [version]')
  .description('Git tag a new version (does not perform release)')
  .action (version) ->
    if not version?
      console.log 'No version specified, reading from debr.json'
    console.log 'tagging'

isFile(debChangeLogPath)
  .then(->
    unless which('git')
      console.error "Needs git installed."
      process.exit 1
    try
      debrInfo = require(debrInfoPath)
    catch e
      curr_cmd = process.argv
      unless "init" in curr_cmd
        console.error "Unable to load ./debr.json, " +
        "please run `debr init`"
        process.exit 1
    return program.parse(process.argv))
  .catch((e) ->
    console.error "Failed to process a required config: #{e}")
