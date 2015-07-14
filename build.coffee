Utils = require('./utils')
Shell = require('shelljs')

# Builds a debian source package which includes the orig.tar.*
module.exports.debSource = (debr, changelog, dst) ->
  clean(dst)
  tarball(debr, changelog, dst)
  Shell.cd(dst)
  excludes = debr.excludes.join("|")
  buildargs = "-us -uc"
  if excludes?
    buildargs = "#{buildargs} -i'#{excludes}'"
  Shell.exec("dpkg-buildpackage -S -sa #{buildargs}")

module.exports.debRelease = (debr, dst) ->
  console.log "Building a release deb (no orig.tar.* included)"
  Shell.cd(dst)
  excludes = debr.excludes.join("|")
  buildargs = "-us -uc"
  if excludes?
    buildargs = "#{buildargs} -i'#{excludes}'"
  Shell.exec("dpkg-buildpackage -S -sd #{buildargs}")

tarball = (debr, changelog, dst) ->
  Shell.cd(dst)
  Shell.cd('..')
  cmd = "tar czf #{changelog.pkgname}_#{changelog.debVersion}.orig.tar.gz " +
        "#{dst} --exclude-vcs --exclude=debian"
  console.log cmd
  Shell.exec(cmd)
  Shell.cd(dst)

clean = (dst) ->
  Shell.cd(dst)
  Shell.exec('debian/rules clean')
