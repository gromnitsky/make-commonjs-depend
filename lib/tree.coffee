fs = require 'fs'
path = require 'path'
detective = require 'detective'

class FNode

  constructor: (@name, mustBeReal = false) ->
    throw new Error "invalid name: '#{@name}'" unless FNode.IsValidName(@name)
    @name = FNode.ResolveName @name if mustBeReal
    @deps = {} # { file_name : FNode }
    @parent = null

  # Return true if name is an absolute or _explicitly_ relative path.
  @IsValidName: (name) ->
    throw new Error "unsupported platform: #{process.platform}" if process.platform == 'win32'

    return true if name.match /^(\/|\.\.\/|\.\/).+/
    false

  @ResolveName: (name) ->
    result = null
    err = null
    for idx in [name, "#{name}.js"]
      try
        result = fs.realpathSync idx
      catch e
        err = e

    throw err if !result
    result

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
    nd = new FNode fname, mustBeReal

    fname = nd.name
    if @isOffspringOf fname
      throw new Error "circular dependency between '#{fname}' & ('#{@name}' or its parents)"

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

  # @resolved is pool of shared, already processed FNodes:
  #
  # { file_name: FNode }
  constructor: (@resolved = {}) ->
    @root = null
    @startDir = process.cwd()

  # Side effect: changes current dir.
  # Return new FNode.
  createRoot: (fname) ->
    fname = FNode.ResolveName fname
    process.chdir path.dirname(fname)
    fname = path.basename fname

    @root = new FNode "./#{fname}", true

  @GetDeps: (fname) ->
    try
      jscript = fs.readFileSync fname
      deps = detective jscript
    catch e
      throw new Error "#{fname} parse error: #{e}"

  # Raise an exception on error.
  # Return nothing.
  breed: (fname, parentNode) ->
    deps = null

    if parentNode
      if @resolved[fname]
        console.log "#{fname} WAS BEFORE (parent: #{parentNode.parent.name})"
        parentNode.parent.deps[fname] = @resolved[fname]
        return
    else
      deps = FTree.GetDeps fname
      parentNode = @createRoot fname

    deps = deps ? FTree.GetDeps fname
    console.log "#{fname} deps:", deps
    save_dir = process.cwd()
    for idx in deps
      process.chdir path.dirname(idx)
      try
        nd = parentNode.depAdd idx, true
        idx = nd.name
      catch e
        console.log "#{idx}: skipping, #{e}"
        process.chdir save_dir
        continue

      # RECURSION
      @breed idx, nd
      @resolved[idx] = nd unless @resolved[idx]
      process.chdir save_dir

    process.chdir @startDir

  print: (fnode, indent = 0) ->
    fnode = @root unless fnode
    unless fnode
      console.log "FTree is empty"
      return

    prefix = ''
    cur_indent = indent
    prefix += " " while cur_indent--

    name = path.basename fnode.name
    console.log "#{prefix}#{name}, deps: #{fnode.depSize()}"
    for key,val of fnode.deps
      @print val, indent+2


exports.FNode = FNode
exports.FTree = FTree
