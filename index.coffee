Promise = require('bluebird')
_ = require('lodash')
fs = require('fs-extra-promise')
DebChangelog = require('deb-changelog')

# Parses debian/changelog
module.exports.parse = (changeLog) ->
  fs.readFileAsync(changeLog, 'utf-8')
    .then((out) ->
      return new DebChangelog(out))
    .catch((e) -> throw Error(e))

module.exports.check = (changelog) ->
  return fs.lstatAsync(changelog)
    .then((stat) ->
      if stat.isFile()
        return true)
    .catch((e) ->
      return throw Error(e))

# Usage example:
#
# checkForChangelog()
#   .then((clPath) ->
#     return parseLog(clPath))
#   .then((cl) ->
#     parsed = _.first(cl.parse())
#     return console.log "#{parsed.pkgname} -> #{parsed.debVersion}")
#   .catch((e) ->
#     return throw Error(e))
