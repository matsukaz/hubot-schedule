Fs = require 'fs'
Path = require 'path'

module.exports = (robot) ->
  scriptsPath = Path.resolve __dirname, 'scripts'
  Fs.exists scriptsPath, (exists) ->
    if exists
      robot.loadFile scriptsPath, file for file in Fs.readdirSync(scriptsPath)

