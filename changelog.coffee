_ = require('lodash')
fs = require('fs-extra-promise')
DebChangelog = require('deb-changelog')

# Parses debian/changelog
module.exports.load = (changeLog) ->
  fs.readFileAsync(changeLog, 'utf-8')
    .then((out) ->
      cl = new DebChangelog(out)
      entries = cl.splitLogs()
      return {
        cl: cl
        entries: entries
        latest: cl.parse(_.first(entries))
      })
    .catch((e) -> throw Error(e))
