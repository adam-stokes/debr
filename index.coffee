class Version
  constructor: (@versionStr) ->
    @versionStrRegex = /// ^
      (\w+)
      \s
      \(
      (\d+\.\d+\.\d+-\d+)
      (.*)\)
      \s
      (\w+);\surgency=(\w+)
      $ ///i
    @match = @versionStr.match @versionStrRegex

  packageName: ->
    if @match
      return @match[1].trim()
    throw Error("Unknown package name.")

  packageVersion: ->
    if @match
      return @match[2].trim()
    throw Error("Cannot find version number.")

  versionMajor: ->
    version = @match[2]
    Regex = /^(\d+)\.\d+\.\d+-\d+/
    major = version.match Regex
    if major
      return parseInt(major[1].trim(), 10)
    throw Error("Cannot find major version number.")

  versionMinor: ->
    version = @match[2]
    Regex = /^\d+\.(\d+)\.\d+-\d+/
    minor = version.match Regex
    if minor
      return parseInt(minor[1].trim(), 10)
    throw Error("Cannot find minor version number.")

  versionPatch: ->
    version = @match[2]
    Regex = /^\d+\.\d+\.(\d+)-\d+/
    patch = version.match Regex
    if patch
      return parseInt(patch[1].trim(), 10)
    throw Error("Cannot find patch version number.")

  ubuntuVersion: ->
    return @match[3].trim()

  series: ->
    return @match[4].trim()

  urgency: ->
    return @match[5].trim()

module.exports = Version
