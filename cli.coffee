#!/usr/bin/env coffee
Promise = require('bluebird')
program = require('commander')
fs = require('fs-extra-promise')
isFile = Promise.promisify(require('is-file'))
_ = require('lodash')
pkgInfo = require('./package.json')
ChangeLog = require('./changelog')
Utils = require('./utils')
Build = require('./build')
Shell = require('shelljs')

Shell.config.silent = true

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

# Initialize a debr.json
# debr init
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
        excludes: [
          ".git.*",
          ".tox",
          ".bzr.*",
          ".editorconfig",
          ".travis-yaml"
        ]
      console.log "Wrote debr.json config, please edit to suite your project."
      return Utils.writeConf(debrInfoPath, model))

# Build debian package with updated changelog entry
# debr build
program
  .command('build')
  .description('Build a debian package from current version')
  .option('-s, --source', 'Builds a source only package')
  .option('-b, --binary', 'Builds a binary only package')
  .option('-o, --output [dir]', 'Destination directory to put build.', '/tmp')
  .action (options) ->
    unless options.output?
      console.error "Needs a -o <dir> output directory."
      process.exit 1
    ChangeLog.load(debChangeLogPath)
      .then((cl) ->
        Utils.cloneRepo(Utils.repo(), options.output)
        if options.source?
          console.log "Building source package in #{options.output}"
        Build.debSource(debrInfo, cl.latest, options.output))
      .catch((e) ->
        return console.log "Problem with build.")

# Parse changelog
# debr changelog [-l]
program
  .command('changelog')
  .description('Parse and display debian/changelog')
  .option('-l, --latest', 'Display latest entry')
  .action (options) ->
    ChangeLog.load(debChangeLogPath)
      .then((out) ->
        if options.latest
          Utils.pj(out.latest)
        else
          for entry in out.entries
            Utils.pj(out.cl.parse(entry))
        return)
      .catch((e) ->
        console.error e
        return process.exit 1)

# Display debr.json config
# debr config
program
  .command('config')
  .description('Displays current debr configuration')
  .action ->
    Utils.pj(debrInfo)

# Set debr.json config item
# debr config-set "author=Pete Rose <pete.rose@gamblinman.com"
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

# Get config item from debr
# debr config-get author
program
  .command('config-get "<key>"')
  .description('Gets config option, ie config-get "releases[0].tag"')
  .action (confKey) ->
    fs.readJSONAsync(debrInfoPath)
      .then((debrParse)->
        console.log _.get(debrParse, confKey) ? "Key: #{confKey} not found."
        return)
      .catch((e) -> console.error "Problem reading config: #{e}")

# List current supported series
# debr series
program
  .command('series')
  .description('List current registered series')
  .action ->
    console.log "Currently registered series:"
    keys = _.sortBy(_.keys(debrInfo.series), (a) -> return a)
    _.each(keys, (k) ->
      console.log _.padLeft("#{k} (#{debrInfo.series[k]})", 20))

# Build a new release
# debr release
program
  .command('new-release')
  .description('Tags, Changes, Builds, and Commit pkg to git.')
  .action ->
    console.log 'new release'

# Add supported series
# debr add-series wily 15.10
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

# Add ppa
# debr add-ppa ppa:juju/stable
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

# List git tags
# debr tag
# Set git tag
# debr tag 1.0.1
program
  .command('tag [version]')
  .description('Git tag a new version (does not perform release)')
  .action (version) ->
    if not version?
      console.log "Existing Tags:"
      return console.log Shell.exec('git tag').output.trim()
    console.log 'tagging'

# Upstream VCS repo
# debr vcs-repo
program
  .command('vcs-repo')
  .description('Displays upstream Git repository. (only supports Git)')
  .action ->
    console.log Utils.repo()

isFile(debChangeLogPath)
  .then(->
    unless Shell.which('git')
      console.error "Needs git installed."
      process.exit 1
    return program.parse(process.argv))
  .catch((e) ->
    console.error "Failed to process a required config: #{e}")
