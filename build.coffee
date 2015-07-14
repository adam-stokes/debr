Utils = require('./utils')
Shell = require('shelljs')
Path = require('path')

debSign = (changelog, dst) ->
  changes_file = "#{changelog.pkgname}_#{changelog.debVersion}" +
                 "-#{changelog.versionExtra}_source.changes"
  cmd = "debsign --re-sign " +
        "-p'gpg --batch --no-tty --passphrase #{Shell.env.DEBSIGNPASS}' " +
        "../#{changes_file}"
  Shell.exec(cmd)

tarball = (debr, changelog, dst) ->
  Shell.cd(dst)
  Shell.cd('..')
  cmd = "tar czf #{changelog.pkgname}_#{changelog.debVersion}.orig.tar.gz " +
        "#{dst} --exclude-vcs --exclude=debian"
  Shell.exec(cmd)
  Shell.cd(dst)

clean = (dst) ->
  Shell.cd(dst)
  Shell.exec('debian/rules clean')

# Builds a debian source package which includes the orig.tar.*
module.exports.debSource = (debr, changelog, dst) ->
  clean(dst)
  tarball(debr, changelog, Path.basename(dst))
  Shell.cd(dst)
  excludes = debr.excludes.join("|")
  buildargs = "-us -uc"
  if excludes?
    buildargs = "#{buildargs} -i'#{excludes}'"
  cmd = "dpkg-buildpackage -S -sa #{buildargs}"
  Shell.exec(cmd)
  debSign(changelog, dst)

module.exports.debRelease = (debr, changelog, dst) ->
  clean(dst)
  tarball(debr, changelog, Path.basename(dst))
  Shell.cd(dst)
  excludes = debr.excludes.join("|")
  buildargs = "-us -uc"
  if excludes?
    buildargs = "#{buildargs} -i'#{excludes}'"
  cmd = "dpkg-buildpackage -S -sd #{buildargs}"
  Shell.exec(cmd)
  debSign(changelog, dst)
