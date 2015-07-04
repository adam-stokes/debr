# debr

fs = require('fs-extra-promise')
meow = require('meow')
symbol = require('log-symbols')
Version = require('.')

cli = meow(
  help: [
    'Usage',
    ' debr <changelog> [opts]',
    '',
    'Eg:',
    ' $ debr debian/changelog',
    ].join('\n')
)

# Parses debian/changelog
parseLog = (changeLog) ->
  fs.readFileAsync(changeLog, 'utf-8')
    .then((out) ->
      lines = out.trim().split('\n')
      firstLine = lines[0]
      return new Version(firstLine))

changeLog = cli.input[0]
unless changeLog?
  console.log(symbol.error, "Needs a debian/changelog file.")
  process.exit 1

parseLog(changeLog)
  .then((version) -> return console.log(symbol.success,
    "#{version.packageName()},
    MAJOR(#{version.versionMajor()}),
    MINOR(#{version.versionMinor()}),
    PATCHLEVEL(#{version.versionPatch()}),
    SERIES(#{version.series()})"))
