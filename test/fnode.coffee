assert = require 'assert'

tree = require '../lib/tree'

suite 'Tree', ->
  setup ->
    process.chdir __dirname

  test 'invalid fnode', ->
    assert.throws -> new tree.FNode()
    assert.throws -> new tree.FNode('  ')
    assert.throws -> new tree.FNode('foo')
    assert.throws -> new tree.FNode('..foo')
    assert.throws -> new tree.FNode('.foo')

  test 'valid fnode', ->
    assert new tree.FNode('/foo')
    assert new tree.FNode('./foo')
    assert new tree.FNode('./foo/bar')
    assert new tree.FNode('../foo')
    assert new tree.FNode('../../foo')

  test 'ancestor search fail', ->
    assert.equal false, new tree.FNode('./foo').isOffspringOf()
    assert.equal false, new tree.FNode('./loser').isOffspringOf('rich-uncle')

  test 'add dependency fail', ->
    assert.throws -> new tree.FNode('./foo').depAdd()
    assert.throws ->
      new tree.FNode('./foo').depAdd('./foo')
    assert.throws ->
      new tree.FNode('./foo').depAdd('./bar').depAdd './foo'
    assert.throws ->
      new tree.FNode('./1').depAdd('./2').depAdd('./3').depAdd('./2')
    assert.throws ->
      new tree.FNode('./1').depAdd('./2').depAdd('./3').depAdd('./1')

  test 'add dependency', ->
    nd = new tree.FNode('./1').depAdd('./2').depAdd('./3').depAdd('./4')
    assert.deepEqual {}, nd.deps
    assert.equal './3', nd.parent.name
    assert.equal './2', nd.parent.parent.name
    assert.equal './1', nd.parent.parent.parent.name
    assert.equal null, nd.parent.parent.parent.parent

  test 'ResolveName fail', ->
    assert.throws -> tree.FNode.ResolveName()
    assert.throws -> tree.FNode.ResolveName "DOESN'T EXIST"

    # because it cannot resolve in current 'test' directory
    assert.throws -> tree.FNode.ResolveName 'test/data/simple/d.js'

  test 'ResolveName symlink', ->
    process.chdir 'data/simple'
    assert tree.FNode.ResolveName('test/data/simple/d.js').match '/test/data/simple/d/d.js'

  test 'ResolveName normal', ->
    process.chdir 'data/simple'
    assert tree.FNode.ResolveName('test/data/simple/a.js').match '/test/data/simple/a.js'
