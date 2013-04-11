fs = require 'fs'
path = require 'path'
detective = require 'detective'

readFile = (name, oneMoreTime = true) ->
  try
    fs.readFileSync name
  catch e
    if oneMoreTime
      readFile("#{name}.js", false)
    else
      ""

class FNode

  constructor: (@name, mustBeReal = false) ->
    throw new Error "invalid name: '#{@name}'" unless FNode.IsValidName(@name)
    @name = fs.realpathSync @name if mustBeReal
    @deps = {} # { file_name : FNode }
    @parent = null

  # Return true if name is an absolute or _explicitly_ relative path.
  @IsValidName: (name) ->
    throw new Error "unsupported platform: #{process.platform}" if process.platform == 'win32'

    return true if name.match /^(\/|\.\.\/|\.\/).+/
    false

  # Return true if fname is our ancestor.
  isOffspringOf: (fname) ->
    return true if @name == fname
    return false unless @parent?.name

    if @parent.name == fname
      true
    else
      # RECURSION
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

  depSize: ->
    Object.keys(@deps).length

# Example:
#
# ft = new FTree()
# ft.breed "a.js"
# ft.print
class FTree

  constructor: ->
    @root = null
    @resolved = {} # { file_name: FNode }

  # Raise an exception on error.
  # Return nothing.
  breed: (fname, parentNode) ->
    if parentNode && !FNode.IsValidName fname
      console.log "#{fname}: ignoring"
      return

    try
      deps = detective (readFile fname)
    catch e
      throw new Error "#{fname} parse error: #{e}"

    unless parentNode
      fname = fs.realpathSync fname
      process.chdir path.dirname(fname)
      fname = path.basename fname

      parentNode = new FNode "./#{fname}"
      @root = parentNode
      @resolved = {}

    console.log process.cwd()
    console.log "#{fname} deps:", deps
    for idx in deps
      # RECURSION
      process.chdir path.dirname(idx)
      try
        nd = parentNode.depAdd idx
      catch e
        console.log "#{idx}: skipping"
        continue

      @breed idx, nd

  print: (fnode, indent = 0) ->
    fnode = @root unless fnode
    unless fnode
      console.log "FTree is empty"
      return

    prefix = ''
    cur_indent = indent
    prefix += " " while cur_indent--

    console.log "#{prefix}#{fnode.name}, deps: #{fnode.depSize()}"
    for key,val of fnode.deps
      @print val, indent+2


exports.FNode = FNode
exports.FTree = FTree
