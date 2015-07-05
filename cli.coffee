#!/usr/bin/env coffee

fs = require('fs-extra-promise')
meow = require('meow')
symbol = require('log-symbols')
path = require('path')
Version = require('.')
Promise = require('bluebird')

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
      lines = out.trim().split('\n')
      firstLine = lines[0]
      return new Version(firstLine))
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

gitConfig = ->
  # check .gitconfig first
  gitPath = process.env['HOME'] + '/.gitconfig'
  fs.lstatAsync(gitPath)
    .then((stat) ->
      if stat.isFile()
        git = ini.parse(fs.readFileSync(gitPath, 'utf-8'))
        console.log git
        return "#{git.user.name} #{git.user.email}")
    .catch((e) -> throw Error(e))

bzrConfig = ->
  # check .bazaar/bazaar.conf next
  bzrPath = process.env['HOME'] + '/.bazaar/bazaar.conf'
  fs.lstatAsync(bzrPath)
    .then((stat) ->
      if stat.isFile()
        bzr = ini.parse(fs.readFileSync(bzrPath, 'utf-8'))
        console.log bzr
        return bzr.DEFAULT.email)
    .catch((e) -> throw Error(e))

config = ->
  gitConfig()
    .then((username) -> return username)
    .catch(->
      try
        return bzrConfig()
      catch e
        throw Error(e))

config()
  .then((user) ->
    return checkForChangelog())
  .then((log) -> return parseLog(log))
  .then((version) ->
    return console.log(symbol.success,
      "#{version.packageName()},
      MAJOR(#{version.versionMajor()}),
      MINOR(#{version.versionMinor()}),
      PATCHLEVEL(#{version.versionPatch()}),
      SERIES(#{version.series()})"))
  .catch((e) ->
    console.log e
    return process.exit 1)
