fs = require 'fs'
detective = require 'detective'

readFile = (name) ->
  try
    fs.readFileSync idx
  catch e
    ""

class FNode

  constructor: (@name, mustBeReal = false) ->
    throw new Error "invalid name: '#{@name}'" unless FNode.IsValidName(@name)
    @name = fs.realpathSync @name if mustBeReal
    @deps = {}
    @parent = null

  # Return true if name is an absolute or _explicitly_ relative path.
  @IsValidName: (name) ->
    throw new Error "unsupported platform: #{process.platform}" if process.platform == 'win32'

    return true if name.match /^(\/|\.\.\/|\.\/).+/
    false

  # Return true if fname is our ancestor.
  isOffspringOf: (fname) ->
#    console.log @name, @parent, fname
    return true if @name == fname
    return false unless @parent?.name
    if @parent.name == fname
      true
    else
      @parent.isOffspringOf fname

  # Raise an exception on error.
  # Overwrite an existing one with equal fname.
  #
  # Return added FNode.
  depAdd: (fname, mustBeReal = false) ->
    fname = fs.realpathSync fname if mustBeReal
    if @isOffspringOf fname
      throw new Error "circular dependency between '#{fname}' & ('#{@name}' or its parents)"

    nd = new FNode fname
    nd.parent = this
    @deps[fname] = nd

    nd

class FTree
  constructor: ->
    @root = null

    # { file_name: FNode }
    @resolved = {}

  # Add to deps of parentNode new node from fname
  #
  # ftree.fill null, "a.js"
  fill: (parentNode, fname) ->
    try
      nd = new FNode fname
    catch e
      console.log "#{fname}: ignoring"
      return

    nd.name = fs.realpathSync nd.name
    try
      deps = detective (readFile dn.name)
    catch e
      throw new Error "#{nd.name} parse error: #{e}"

    if parentNode == null
      @root = nd
      @resolved = {}
    else
      if @resolved[nd.name]
        parentNode.push @resolved[nd.name]
        return
      else
        parentNode.push nd

    @resolved[nd.name] = nd
    for idx in deps
      @fill nd, idx

exports.FNode = FNode
exports.FTree = FTree
