#!/usr/bin/env coffee
meow = require('meow')

cli = meow(help: [
  'Usage',
  ' debr cmd [opts]',
  '',
  ' tag        Git tag a new version (does not perform release)',
  ' release    Tags, Changes, Builds, and Commit pkg to git.',
  ' changelog  Generates a debian/changelog',
  '',
  'General Options',
  ' -d --debug  Enable debugging'
  '',
  'Eg:',
  ' $ debr release',
  ' $ debr changelog'
])

action = cli.input[0]
debug = cli.flags.d || cli.flags.debug

if debug?
  console.log cli

if not action?
  console.error "Needs a subcommand, eg (release|changelog)"
  process.exit 1

switch action
  when "release" then console.log "performing a release"
  when "changelog" then console.log "printing changelog"
  else console.log "HAPPY!"
