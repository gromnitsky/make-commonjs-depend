path = require 'path'

exports.VERBOSE = 0
exports.QUIET = false

exports.puts = (level, who) ->
  arguments[2] = "#{who}: #{arguments[2]}" if arguments?.length > 2 && who != ""
  msg = (val for val, idx in arguments when idx > 1)
  console.log.apply(console, msg) if level <= exports.VERBOSE

exports.pnGet = ->
  path.basename process.argv[1]

exports.errx = (exit_code, msg) ->
  console.error "#{exports.pnGet()} error: #{msg}" unless exports.QUIET
  process.exit exit_code if exit_code

exports.warnx = (msg) ->
  console.error "#{exports.pnGet()} warning: #{msg}" unless exports.QUIET
