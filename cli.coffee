#!/usr/bin/env coffee
Promise = require('bluebird')
program = require('commander')
fs = require('fs-extra-promise')
isFile = Promise.promisify(require('is-file'))
prettyjson = require('prettyjson')
_ = require('lodash')
pkgInfo = require('./package.json')
ChangeLog = require('.')
Utils = require('./utils')
require('shelljs/global')

debrInfoPath = process.cwd() + '/debr.json'
debChangeLogPath = process.cwd() + '/debian/changelog'

try
  debrInfo = require(debrInfoPath)
catch e
  curr_cmd = process.argv
  unless "init" in curr_cmd
    console.error "Unable to load ./debr.json, " +
    "please run `debr init`"
    process.exit 1

program
  .version("debr v#{pkgInfo.version}")

program
  .command('init')
  .description('Initialize a debr project')
  .action ->
    isFile(debrInfoPath)
    .then(->
      console.log "debr.json exists! not overwriting."
      return)
    .catch(->
      model =
        author: "Your Name <your.name@example.com>"
        series:
          wily: "15.10"
          vivid: "15.04"
          utopic: "14.10"
          trusty: "14.04"
        ppas: [
          'ppa:<project>/<branch>'
        ]
      console.log "Wrote debr.json config, please edit to suite your project."
      return Utils.writeConf(debrInfoPath, model))
program
  .command('build')
  .description('Build a debian package from current version')
  .action ->
    console.log 'building'
program
  .command('changelog')
  .description('Parse and display debian/changelog')
  .option('-l, --latest', 'Display latest entry')
  .action (options) ->
    ChangeLog.parse(debChangeLogPath)
      .then((cl) ->
        entries = cl.splitLogs()
        if options.latest
          console.log(prettyjson.render(cl.parse(_.first(entries))))
        else
          for entry in entries
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
  .command('add-series <series> <version>')
  .description('Register a new series')
  .action (series, version) ->
    debrInfo['series'][series] = version
    fs.writeJSONAsync(debrInfoPath, debrInfo, {spaces: 2})
      .then(->
        console.log "Registered series: #{series}"
        return)
      .catch((e) -> console.error "Problem saving config: #{e}")
program
  .command('add-ppa <ppa:location/branch>')
  .description('Register a new ppa location')
  .action (location) ->
    debrInfo['ppas'].push location
    fs.writeJSONAsync(debrInfoPath, debrInfo, {spaces: 2})
      .then(->
        console.log "Added ppa: #{location}"
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
    return program.parse(process.argv))
  .catch((e) ->
    console.error "Failed to process a required config: #{e}")
