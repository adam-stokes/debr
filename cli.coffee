#!/usr/bin/env coffee
program = require('commander')
fs = require('fs-extra-promise')
prettyjson = require('prettyjson')
_ = require('lodash')
pkgInfo = require('./package.json')
ChangeLog = require('.')

debrInfoPath = process.cwd() + '/debr.json'
debChangeLogPath = process.cwd() + '/debian/changelog'

try
  debrInfo = require(debrInfoPath)
catch e
  console.error "Unable to load ./debr.json: #{e}"
  process.exit 1

program
  .version("debr v#{pkgInfo.version}")

program
  .command('build')
  .description('Build a debian package from current version')
  .action ->
    console.log 'building'
program
  .command('changelog')
  .description('Parse existing debian/changelog')
  .action ->
    try
      ChangeLog.check(debChangeLogPath)
    catch e
      console.error "Could not find debian/changelog: #{e}"
    ChangeLog.parse(debChangeLogPath)
      .then((cl) ->
        for entry in cl.splitLogs()
          console.log(cl.parse(entry))
        return)
      .catch((e) ->
        console.error e
        return process.exit 1)
program
  .command('config')
  .description('Displays current package configuration')
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

program.parse process.argv
