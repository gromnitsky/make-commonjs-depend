assert = require 'assert'

tree = require '../lib/tree'

suite 'Tree', ->
  setup ->
    process.chdir __dirname

  test 'invalid fnode', ->
    assert.throws -> new tree.FNode()
    assert.throws -> new tree.FNode(null, '  ')
    assert.throws -> new tree.FNode(null, 'foo')
    assert.throws -> new tree.FNode(null, '..foo')
    assert.throws -> new tree.FNode(null, '.foo')

  test 'valid fnode', ->
    assert new tree.FNode(null, '/foo')
    assert new tree.FNode(null, './foo')
    assert new tree.FNode(null, './foo/bar')
    assert new tree.FNode(null, '../foo')
    assert new tree.FNode(null, '../../foo')

  test 'ancestor search fail', ->
    assert.equal false, new tree.FNode(null, './foo').isOffspringOf()
    assert.equal false, new tree.FNode(null, './loser').isOffspringOf('rich-uncle')

  test 'add dependency fail', ->
    assert.throws -> new tree.FNode(null, './foo').depAdd()
    assert.throws ->
      new tree.FNode(null, './foo').depAdd(null, './foo')
    assert.throws ->
      new tree.FNode(null, './foo').depAdd(null, './bar').depAdd null, './foo'
    assert.throws ->
      new tree.FNode(null, './1').depAdd(null, './2').depAdd(null, './3').depAdd(null, './2')
    assert.throws ->
      new tree.FNode(null, './1').depAdd(null, './2').depAdd(null, './3').depAdd(null, './1')

  test 'add dependency', ->
    nd = new tree.FNode(null, './1').depAdd(null, './2').depAdd(null, './3').depAdd(null, './4')
    assert.deepEqual {}, nd.deps
    assert.equal './3', nd.parent.name
    assert.equal './2', nd.parent.parent.name
    assert.equal './1', nd.parent.parent.parent.name
    assert.equal null, nd.parent.parent.parent.parent

  test 'ResolveName2 fail', ->
    assert.throws -> tree.FNode.ResolveName2()
    assert.throws -> tree.FNode.ResolveName2("PATH DOESN'T EXIST")
    assert.throws -> tree.FNode.ResolveName2(null, "PATH DOESN'T EXIST")

    # directories are no good
    assert.throws ->
      tree.FNode.ResolveName2 null, "data/broken/dir/.."
    , /\/data\/broken.node/

  test 'ResolveName2 symlink', ->
    assert tree.FNode.ResolveName2(null, 'data/simple/d.js').match '/data/simple/d/d.js'
    assert tree.FNode.ResolveName2('data/simple', 'd.js').match '/data/simple/d/d.js'

  test 'ResolveName2 normal', ->
    assert tree.FNode.ResolveName2('data', 'simple/a.js').match '/test/data/simple/a.js'
