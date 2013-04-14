class PrinterError extends Error
  constructor: (msg) ->
    @name = @constructor.name
    @message = "Printer: #{msg}"
    Error.captureStackTrace this, @name

# Abstract
class Printer

  constructor: (ftree, @readStream, @opt) ->
    throw new PrinterError 'invalid tree' unless ftree?.root
    @tree = ftree.root

    throw new PrinterError 'invalid readable stream' unless @readStream?.readable
    @opt = {} unless @opt

  conciseName: (name) ->
    name.replace (new RegExp "^#{process.cwd()}/?"), ''

  print: ->
    throw new Error 'not implemented'

# Draw a very simple tree with indented nodes.
class DumbTreePrinter extends Printer
  @INDENT_STEP: 2

  print: (fnode, indent = 0) ->
    fnode = @tree unless fnode
    return unless fnode

    prefix = ''
    cur_indent = indent
    prefix += " " while cur_indent--

    name = @conciseName fnode.name
    @readStream.emit 'data', "#{prefix}#{name}, deps: #{fnode.depSize()}\n"
    for key,val of fnode.deps
      # RECURSION
      @print val, indent+DumbTreePrinter.INDENT_STEP

class MakefilePrinter extends Printer

  constructor: (ftree, readStream, opt) ->
    super ftree, readStream, opt
    @opt.prefix = '' unless @opt.prefix?
    @opt.completedJobs = {} unless @opt.completedJobs?

  print: (fnode) ->
    fnode = @tree unless fnode
    return unless fnode

    target_name = @conciseName fnode.name
    # don't print already printed
    return if @opt.completedJobs[target_name]

    target_spec = "#{target_name}:"

    deps = []
    for key,val of fnode.deps
      key = @conciseName key
      target_spec += " \\\n  #{key}"
      deps.push val

    @readStream.emit 'data', "#{@opt.prefix}#{target_spec}\n"
    @opt.completedJobs[target_name] = true

    # RECURSION
    @print idx for idx in deps


exports.DumbTreePrinter = DumbTreePrinter
exports.MakefilePrinter = MakefilePrinter
