assert = require 'assert'
fs = require 'fs'
execSync = require 'execSync'

suite 'Cmd output', ->
  setup ->
    process.chdir __dirname
    @cmd = '../bin/make-commonjs-depend'

  test 'makefile', ->
    r = execSync.exec "#{@cmd} data/simple/*.js"
    assert.equal (fs.readFileSync 'data/simple/output.makefile').toString(), r.stdout

  test 'makefile with prefix & recipe', ->
    r = execSync.exec "#{@cmd} -p QQQ/ --mk-recipe WWW data/simple/*.js"
    assert.equal (fs.readFileSync 'data/simple/output.makefile.prefix_and_recipe').toString(), r.stdout

  test 'dot', ->
    r = execSync.exec "#{@cmd} data/simple/*.js -m dot"
    assert.equal (fs.readFileSync 'data/simple/output.dot').toString(), r.stdout

  test 'tree-dumb', ->
    r = execSync.exec "#{@cmd} data/simple/*.js -m tree-dumb"
    assert.equal (fs.readFileSync 'data/simple/output.tree-dumb').toString(), r.stdout
