fs = require 'fs'
path = require 'path'
detective = require 'detective'

fub = require './funcbag'

class FNodeError extends Error
  constructor: (msg) -> fub.makeError FNodeError, this, 'FNode', msg

class FNodeDepError extends Error
  constructor: (msg) -> fub.makeError FNodeDepError, this, 'FNodeDep', msg

class FNode

  constructor: (relativeToPath, @name, @opt) ->
    throw new FNodeError "unwanted name: '#{@name}'" unless FNode.IsValidName(@name)
    unless @opt
      @opt = {}
      @opt.mustBeReal = false
      @opt.circularLinksCheck = true

    @name = FNode.ResolveName2 relativeToPath, @name if @opt.mustBeReal
    @deps = {} # { file_name : FNode }
    @parent = null

  # Return true if name is an absolute or _explicitly_ relative path.
  @IsValidName: (name) ->
    throw new FNodeError "unsupported platform: #{process.platform}" if process.platform == 'win32'

    # TODO: check if it's valid in Windows
    return true if name.match /^(\/|\.\.\/|\.\/).+/
    false

  # Raise an exception on error.
  # Does follow symlinks.
  #
  # Return an absolute file name.
  @ResolveName2: (relativeToPath, name) ->
    throw new FNodeError 'empty name' unless name

    fub.puts 2, '\nRN0', 'rel=%s, name=%s', relativeToPath, name
    result = null
    err = null
    relativeToPath = '' unless relativeToPath
    name = path.resolve relativeToPath, name

    for idx in [name, "#{name}.js", "#{name}.json", "#{name}.node"]
      fub.puts 2, 'RN1', idx
      try
        result = fs.realpathSync idx
        if fs.statSync(result).isDirectory()
          result = null
          continue

        fub.puts 2, 'RN', result
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
  depAdd: (relativeToPath, fname) ->
    nd = new FNode relativeToPath, fname, @opt

    fname = nd.name
    exception_type = if @opt.circularLinksCheck then FNodeDepError else FNodeError
    if @isOffspringOf fname
      throw new exception_type "circular link between '#{fname}' & ('#{@name}' or its parents)"

    nd.parent = this
    @deps[fname] = nd

    nd

  depSize: ->
    Object.keys(@deps).length


class FTreeError extends Error
  constructor: (msg) -> fub.makeError FTreeError, this, 'FNodeDep', msg

# Example:
#
# ft = new FTree()
# ft.breed "a.js"
class FTree

  # @resolved is pool of shared, already processed FNodes:
  #
  # { file_name: FNode }
  constructor: (@fnodeOpt, @resolved = {}) ->
    @root = null
    unless @fnodeOpt
      @fnodeOpt = {}
      @fnodeOpt.mustBeReal = true
      @fnodeOpt.circularLinksCheck = true

  # Raise an exception on error.
  # Return new FNode.
  createRoot: (fname) ->
    dir = path.dirname(fname)
    fname = path.basename fname
    @root = new FNode dir, "./#{fname}", @fnodeOpt

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
  breed: (relativeToPath, fname, parentNode) ->
    throw new FTreeError 'empty fname' unless fname
    relativeToPath = '' unless relativeToPath
    fname = path.resolve relativeToPath, fname
    deps = null

    if parentNode
      if @resolved[fname]
        fub.puts 1, 'breed', '%s: WAS BEFORE: parent: %s', fname, parentNode.parent.name
        parentNode.parent.deps[fname] = @resolved[fname]
        return
    else
      deps = FTree.GetDeps fname
      parentNode = @createRoot fname
      relativeToPath = path.dirname @root.name

    deps = deps ? FTree.GetDeps fname
    fub.puts 1, 'breed', '%s: deps:', fname, deps

    for idx in deps
      rel_dir = relativeToPath
      try
        nd = parentNode.depAdd rel_dir, idx
        idx = nd.name
        rel_dir = path.dirname idx
      catch e
        if e instanceof FNodeError
          fub.puts 1, 'breed', '%s: SKIPPING: %s', idx, e.message
          continue
        throw e

      # RECURSION
      @breed rel_dir, idx, nd
      @resolved[idx] = nd unless @resolved[idx]

exports.FNodeError = FNodeError
exports.FNodeDepError = FNodeDepError
exports.FNode = FNode

exports.FTreeError = FTreeError
exports.FTree = FTree
