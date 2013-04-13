fs = require 'fs'
path = require 'path'
detective = require 'detective'

fub = require './funcbag'

class FNodeError extends Error
  constructor: (msg) ->
    @name = @constructor.name
    @message = "FNode: #{msg}"
    Error.captureStackTrace this, @name

class FNodeDepError extends Error
  constructor: (msg) ->
    @name = @constructor.name
    @message = "FNodeDep: #{msg}"
    Error.captureStackTrace this, @name

class FNode

  constructor: (@name, mustBeReal = false) ->
    throw new FNodeError "unwanted name: '#{@name}'" unless FNode.IsValidName(@name)
    @name = FNode.ResolveName @name if mustBeReal
    @deps = {} # { file_name : FNode }
    @parent = null

  # Return true if name is an absolute or _explicitly_ relative path.
  @IsValidName: (name) ->
    throw new FNodeError "unsupported platform: #{process.platform}" if process.platform == 'win32'

    return true if name.match /^(\/|\.\.\/|\.\/).+/
    false

  # Raise an exception on error.
  # Does follow symlinks.
  #
  # May change CWD.
  # Return an absolute file name.
  @ResolveName: (name) ->
    throw new FNodeError 'empty name' unless name

    result = null
    err = null
    name = path.basename name

    for idx in [name, "#{name}.js", "#{name}.json", "#{name}.node"]
      fub.puts 2, '\nRN1', 'idx=%s cwd=%s', idx, process.cwd()
      try
        result = fs.realpathSync idx
        continue if fs.statSync(result).isDirectory()

        # symlink may resolve to a another dir
        process.chdir path.dirname(result)
        fub.puts 2, '\nRN1', 'cwd=%s r=%s', process.cwd(), result
        break
      catch e
        err = new FNodeError(e.message)

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
      throw new FNodeDepError "circular link between '#{fname}' & ('#{@name}' or its parents)"

    nd.parent = this
    @deps[fname] = nd

    nd

  depSize: ->
    Object.keys(@deps).length


class FTreeError extends Error
  constructor: (msg) ->
    @name = @constructor.name
    @message = "FTree: #{msg}"
    Error.captureStackTrace this, @name

# Example:
#
# ft = new FTree()
# ft.breed "a.js"
# ft.print()
class FTree

  # @resolved is pool of shared, already processed FNodes:
  #
  # { file_name: FNode }
  constructor: (@resolved = {}) ->
    @root = null
    @startDir = process.cwd()

  # Side effects: changes current dir.
  # Return new FNode.
  createRoot: (fname) ->
    dir = path.dirname(fname)
    try
      process.chdir dir
    catch e
      throw new FTreeError "chdir failed: #{e}: #{dir}"

    fname = path.basename fname
    @root = new FNode "./#{fname}", true

  # Raise an exception on error.
  # Return an array of (incomplete) file names.
  @GetDeps: (fname) ->
    throw new FNodeDepError "no file name specified" unless fname
    try
      jscript = fs.readFileSync fname
      deps = detective jscript
    catch e
      throw new FNodeDepError "#{fname} parse error: #{e}"

  # Raise an exception on error.
  # Return nothing.
  breed: (fname, parentNode) ->
    deps = null

    if parentNode
      if @resolved[fname]
        fub.puts 1, 'breed', '%s: WAS BEFORE: parent: %s', fname, parentNode.parent.name
        parentNode.parent.deps[fname] = @resolved[fname]
        return
    else
      deps = FTree.GetDeps fname
      parentNode = @createRoot fname

    deps = deps ? FTree.GetDeps fname
    fub.puts 1, 'breed', '%s: deps:', fname, deps
    save_dir = process.cwd()
    for idx in deps
      process.chdir path.dirname(idx)
      try
        nd = parentNode.depAdd idx, true
        idx = nd.name
      catch e
        if e instanceof FNodeError
          fub.puts 1, 'breed', '%s: SKIPPING: %s', idx, e.message
          process.chdir save_dir
          continue
        throw e

      # RECURSION
      @breed idx, nd
      @resolved[idx] = nd unless @resolved[idx]
      process.chdir save_dir

    process.chdir @startDir

  print: (fnode, indent = 0) ->
    fnode = @root unless fnode
    unless fnode
      fun.puts 1, 'print', 'FTree is empty'
      return

    prefix = ''
    cur_indent = indent
    prefix += " " while cur_indent--

    re = new RegExp "^#{process.cwd()}/?"
    name = fnode.name.replace re, ''
    console.log "#{prefix}#{name}, deps: #{fnode.depSize()}"
    for key,val of fnode.deps
      @print val, indent+2


exports.FNodeError = FNodeError
exports.FNodeDepError = FNodeDepError
exports.FNode = FNode

exports.FTreeError = FTreeError
exports.FTree = FTree
