#!/usr/bin/env coffee
program = require('commander')
fs = require('fs-extra-promise')
prettyjson = require('prettyjson')
pkgInfo = require('./package.json')

debrInfo = process.cwd() + '/debr.json'
try
  debrInfo = require(debrInfo)
catch e
  console.error "Unable to load ./debr.json: #{e}"
  process.exit 1

program
  .version("debr v#{pkgInfo.version}")

program
  .command('config')
  .description('Displays current package configuration')
  .action ->
    console.log(prettyjson.render(debrInfo, {
      keysColor: 'grey'
      dashColor: 'red'
    }))
program
  .command('tag [version]')
  .description('Git tag a new version (does not perform release)')
  .action (version) ->
    if not version?
      console.log 'No version specified, reading from debr.json'
    console.log 'tagging'
program
  .command('build')
  .description('Build a debian package from current version')
  .action ->
    console.log 'building'
program
  .command('changelog')
  .description('Generate a changelog from package')
  .action ->
    console.log 'generating changelog'
program
  .command('new-release')
  .description('Tags, Changes, Builds, and Commit pkg to git.')
  .action ->
    console.log 'new release'
program
  .command('available-series')
  .description('List current registered series')
  .action ->
    console.log "Currently registered series:"
    for k,v of debrInfo.series
      console.log "- #{k}"
program
  .command('new-series <series>')
  .description('Register a new series')
  .action (series) ->
    console.log "Registering series: #{series}"

program.parse process.argv
