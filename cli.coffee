#!/usr/bin/env coffee
Promise = require('bluebird')
_ = require('lodash')
fs = require('fs-extra-promise')
meow = require('meow')
DebChangelog = require('deb-changelog')

cli = meow(help: [
  'Usage',
  ' debr <changelog> [opts]',
  '',
  'Eg:',
  ' $ debr debian/changelog',
])

# Parses debian/changelog
parseLog = (changeLog) ->
  fs.readFileAsync(changeLog, 'utf-8')
    .then((out) ->
      return new DebChangelog(out))
    .catch((e) -> throw Error(e))

checkForChangelog = ->
  changelog = cli.input[0]
  if changelog?
    return Promise.resolve(changelog)
  logPath = process.cwd() + '/debian/changelog'
  return fs.lstatAsync(logPath)
    .then((stat) ->
      if stat.isFile()
        return logPath)
    .catch((e) ->
      return throw Error(e))

checkForChangelog()
  .then((clPath) ->
    return parseLog(clPath))
  .then((cl) ->
    parsed = _.first(cl.parse())
    return console.log "#{parsed.pkgname} -> #{parsed.debVersion}")
  .catch((e) ->
    return throw Error(e))
