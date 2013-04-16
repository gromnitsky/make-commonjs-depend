assert = require 'assert'

tree = require '../lib/tree'

suite 'Tree', ->
  setup ->
    process.chdir __dirname
    @read_nodes = {}
    @t = new tree.FTree null, @read_nodes

  test 'empty tree', ->
    assert.equal null, @t.root

  test 'createRoot fail', ->
    assert.throws =>
       @t.createRoot()
    , tree.FNodeError

    assert.throws =>
      @t.createRoot 'DOES NOT/EXIST/foo.js'
    , tree.FNodeError

  test 'createRoot', ->
    @t.createRoot 'data/simple/d.js'
    assert @t.root.name.match '/test/data/simple/d/d.js'

  test 'GetDeps fail', ->
    assert.throws ->
      tree.FTree.GetDeps()
    , /no file name specified/

    assert.throws ->
      tree.FTree.GetDeps "DOESN'T EXIST"
    , /ENOENT/

    assert.throws ->
      tree.FTree.GetDeps "../bin/make-commonjs-depend"
    , /parse error/

  test 'GetDeps', ->
    assert.deepEqual [], tree.FTree.GetDeps 'data/simple/d/d.js'
    assert.deepEqual ["./b.js","./c/c","system-wide"], tree.FTree.GetDeps 'data/simple/a.js'

  test 'breed fail', ->
    assert.throws =>
      @t.breed()
    , tree.FTreeError

  test 'breed simple/a.js & simple/b.js', ->
    # read 1st source file
    @t.breed null, 'data/simple/a.js'
    assert.equal 2, @t.root.depSize()
    assert.equal 3, Object.keys(@read_nodes).length

    a = @t.root
    adeps = Object.keys a.deps
    assert a.deps[adeps[0]].name.match '/data/simple/b.js'
    assert a.deps[adeps[1]].name.match '/data/simple/c.js'

    b = a.deps[adeps[0]]
    bdeps = Object.keys b.deps
    assert.equal 1, b.depSize()
    assert b.deps[bdeps[0]].name.match '/data/simple/c.js'

    c = b.deps[bdeps[0]]
    cdeps = Object.keys c.deps
    assert.equal 1, c.depSize()
    assert c.deps[cdeps[0]].name.match '/data/simple/d/d.js'

    assert.equal c, a.deps[adeps[1]]

    # read 2nd source file but with existing non-empty resolved nodes
    # data
    process.chdir __dirname
    foo = new tree.FTree null, @read_nodes
    foo.breed null, 'data/simple/b.js'
    assert.equal 1, foo.root.depSize()

    key = (Object.keys foo.root.deps)[0]
    assert.equal c, foo.root.deps[key]

  test 'raise FNodeDepError exception for circular deps', ->
    assert.throws =>
      @t.breed null, 'data/broken/circular/a.js'
    , tree.FNodeDepError

  test "don't raise FNodeDepError exception for circular deps", ->
    @t.fnodeOpt.circularLinksCheck = false
    @t.breed null, 'data/broken/circular/a.js'
    assert.equal 1, @t.root.depSize()

    a = @t.root
    adeps = Object.keys a.deps
    assert a.deps[adeps[0]].name.match '/data/broken/circular/b.js'

    b = a.deps[adeps[0]]
    bdeps = Object.keys b.deps
    assert.equal 1, b.depSize()
    assert b.deps[bdeps[0]].name.match '/data/broken/circular/c.js'

    c = b.deps[bdeps[0]]
    assert c.parent == b
    cdeps = Object.keys c.deps
    assert.equal 0, c.depSize()

  test 'ignore directory as a dependency', ->
    @t.breed null, 'data/broken/dir/a.js'
    assert.equal 0, @t.root.depSize()
