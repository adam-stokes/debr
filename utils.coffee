fs = require('fs-extra-promise')

module.exports.writeConf = (path, model) ->
  return fs.writeJSONAsync(path, model, {spaces: 2})
