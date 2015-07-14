Utils = require('./utils')
Shell = require('shelljs')

# Builds a debian source package which includes the orig.tar.*
module.exports.debSource = (debr, dst) ->
  console.log "Building a source deb (orig.tar.* included)"
  tarball(debr, dst)
  cd(dst)
  excludes = debr.excludes.join("|")
  buildargs = "-us -uc"
  if excludes?
    buildargs = "#{buildargs} -i'#{excludes}'"
  exec("dpkg-buildpackage -S -sa #{buildargs}")

module.exports.debRelease = (debr, dst) ->
  console.log "Building a release deb (no orig.tar.* included)"
  cd(dst)
  excludes = debr.excludes.join("|")
  buildargs = "-us -uc"
  if excludes?
    buildargs = "#{buildargs} -i'#{excludes}'"
  exec("dpkg-buildpackage -S -sd #{buildargs}")

module.exports.tarball = (debr, dst) ->
  cd(dst)
  cd('..')
  exec("tar czf #{debr.debVersion}.orig.tar.gz #{dst} " +
       "--exclude-vcs --exclude=debian")
  cd(dst)

module.exports.clean = (dst) ->
  cd(dst)
  exec('debian/rules clean')
