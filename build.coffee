Promise = require('bluebird')
Utils = require('./utils')
Shell = require('shelljs')
Path = require('path')
Fs = require('fs-extra-promise')


class Build
  constructor: (@debrInfo, @entry, @options) ->
    @changes_file = "#{@entry.pkgname}_#{@entry.version}" +
                    "#{@entry.versionExtra}_source.changes"
    @tar_file = "#{@entry.pkgname}_#{@entry.version[..-3]}.orig.tar.gz"

  debSign: ->
    console.log "Signing: #{@changes_file}"
    cmd = "debsign --re-sign " +
          "-p'gpg --batch --no-tty --passphrase #{Shell.env.DEBSIGNPASS}' " +
          "../#{@changes_file}"
    Shell.exec(cmd)

  tarball: (toplevel)->
    Shell.cd(@options.output)
    Shell.cd('..')
    cmd = "tar czf #{@tar_file} " +
          "#{toplevel} --exclude-vcs --exclude=debian"
    console.log "Archiving: #{cmd}"
    Shell.exec(cmd)
    Shell.cd(@options.output)

  clean: ->
    console.log "Cleaning: #{@options.output}"
    Shell.cd(@options.output)
    Shell.exec('debian/rules clean')

  writeChangelog: ->
    changelogOut = """
    #{@entry.pkgname} (#{@entry.version}#{@entry.versionExtra}) #{@entry.series}; urgency=#{@entry.priority}

      * Autopackaged by debr.

     -- #{@entry.firstname} #{@entry.lastname} #{@entry.email} #{@entry.timestamp}
    """
    Fs.outputFileSync("#{@options.output}/debian/changelog", changelogOut)

  debSource: ->
    @tarball(Path.basename(@options.output))
    Shell.cd(@options.output)
    excludes = @debrInfo.excludes.join("|")
    buildargs = "-us -uc"
    if excludes?
      buildargs = "#{buildargs} -i'#{excludes}'"
    cmd = "dpkg-buildpackage -S -sa #{buildargs}"
    console.log "Building: #{cmd}"
    Shell.exec(cmd)
    @debSign()

  debRelease: ->
    Shell.cd(@options.output)
    excludes = @debrInfo.excludes.join("|")
    buildargs = "-us -uc"
    if excludes?
      buildargs = "#{buildargs} -i'#{excludes}'"
    cmd = "dpkg-buildpackage -S -sd #{buildargs}"
    console.log "Building: #{cmd}"
    Shell.exec(cmd)
    @debSign()

  dput: ->
    Shell.exec("dput #{@debrInfo.ppas[0]} ../#{@changes_file}")

module.exports = Build
