#!/usr/bin/env coffee
Promise = require('bluebird')
program = require('commander')
fs = require('fs-extra-promise')
isFile = Promise.promisify(require('is-file'))
semver = require('semver')
_ = require('lodash')
pkgInfo = require('./package.json')
ChangeLog = require('./changelog')
Utils = Promise.promisifyAll(require('./utils'))
Build = require('./build')
Shell = require('shelljs')
Moment = require('moment')

Shell.config.silent = true

debrInfoPath = process.cwd() + '/.debr.json'
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
        latest_version: null,
        series:
          wily: "15.10.1"
          vivid: "15.04.1"
          utopic: "14.10.1"
          trusty: "14.04.1"
        tag: "bleed1"
        ppa: null,
        excludes: [
          ".git.*",
          ".tox.*",
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
  .option('-i, --increment', 'Increment package version during build')
  .option('-o, --output [dir]', 'Destination directory to put build.', '/tmp')
  .option('-u, --upload', 'Upload to PPA')
  .action (options) ->
    unless options.output?
      console.error "Needs a -o <dir> output directory."
      process.exit 1
    if options.upload? and !debrInfo.ppa?
      console.error "Specified upload, but no ppa set."
      process.exit 1
    ChangeLog.load(debChangeLogPath)
      .then((cl) ->
        Utils.cloneRepo(Utils.repo(), options.output)
        return cl)
      .then((cl) ->
        if options.increment?
          if not debrInfo.latest_version?
            debrInfo.latest_version = semver.inc(cl.latest.version,
              'prepatch')
          else
            debrInfo.latest_version = semver.inc(debrInfo.latest_version,
              'prepatch')
        cl.latest.version = debrInfo.latest_version
        Utils.writeConf(debrInfoPath, debrInfo)

        for series in _.keys(debrInfo.series)
          seriesVersion = debrInfo.series[series]
          cl.latest.series = series
          cl.latest.versionExtra = "ubuntu1~#{seriesVersion}~#{debrInfo.tag}"
          cl.latest.timestamp = Moment().format 'ddd, DD MMM YYYY HH:mm:ss ZZ'
          builder = new Build(debrInfo, cl.latest, options)
          builder.writeChangelog()
          Shell.cd(options.output)
          Shell.cd('..')
          if !isFile.sync(builder.tar_file)
            builder.clean()
            builder.debSource()
          else
            builder.debRelease()
        return)
      .catch((e) ->
        return console.log "Problem with build: #{e}")

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
    Utils.writeConf(debrInfoPath, debrInfo)
    return console.log "Saved '#{confKey}=#{confVal}' to config"

# Get config item from debr
# debr config-get author
program
  .command('config-get "<key>"')
  .description('Gets config option, ie config-get "series.wily"')
  .action (confKey) ->
    debrInfo = fs.readJsonSync(debrInfoPath)
    return console.log _.get(debrInfo, confKey) ? "Key: #{confKey} not found."

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

# Add supported series
# debr add-series wily 15.10
program
  .command('add-series <series> <version>')
  .description('Register a new series')
  .action (series, version) ->
    debrInfo['series'][series] = version
    Utils.writeConf(debrInfoPath, debrInfo)
    return console.log "Registered series: #{series}"

# Add ppa
# debr add-ppa ppa:juju/stable
program
  .command('add-ppa <ppa:location/branch>')
  .description('Register a new ppa location')
  .action (location) ->
    debrInfo['ppa'] = location
    Utils.writeConf(debrInfoPath, debrInfo)
    return console.log "Added ppa: #{location}"

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
    Utils.repo()
      .then((out) -> return console.log out)
      .catch((e) -> return throw Error(e))

isFile(debChangeLogPath)
  .then(->
    unless Shell.which('git')
      console.error "Needs git installed."
      process.exit 1
    return program.parse(process.argv))
  .catch((e) ->
    console.error "Failed to process a required config: #{e}")
