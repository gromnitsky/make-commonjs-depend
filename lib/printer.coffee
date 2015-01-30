class PrinterError extends Error
  constructor: (msg) ->
    @name = @constructor.name
    @message = "Printer: #{msg}"
    Error.captureStackTrace this, @name

# Abstract
class Printer

  constructor: (@ftree, @output, @opt) ->
    throw new PrinterError 'invalid tree' unless @ftree?.root
    @tree = @ftree.root

    throw new PrinterError 'invalid readable stream' unless @output?.writable
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
    @output.write "#{prefix}#{name}, deps: #{fnode.depSize()}\n"
    for key,val of fnode.deps
      # RECURSION
      @print val, indent+DumbTreePrinter.INDENT_STEP

class MakefilePrinter extends Printer

  constructor: (ftree, output, opt) ->
    super ftree, output, opt
    @opt.prefix = '' unless @opt.prefix?
    @opt.completedJobs = {} unless @opt.completedJobs?
    @opt.recipe = '' unless @opt.recipe?

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

    target_spec += "\n\t#{@opt.recipe}" if @opt.recipe && fnode.depSize() != 0

    @output.write "#{@opt.prefix}#{target_spec}\n"
    @opt.completedJobs[target_name] = true

    # RECURSION
    @print idx for idx in deps


class DotPrinter extends Printer

  constructor: (ftree, output, opt) ->
    super ftree, output, opt
    @opt.completedJobs = {} unless @opt.completedJobs?

    throw new Error 'invalid graphviz obj' unless @opt.g

  generate: (fnode, cluster) ->
    fnode = @tree unless fnode
    return unless fnode

    target_name = @conciseName fnode.name
    # don't add already added
    return if @opt.completedJobs[target_name]

    if cluster
      nn = @opt.g.addNode target_name
    else
      cluster = @opt.g.addCluster("cluster_#{@ftree.index}")
      cluster.set 'color', 'slategray'
      nn = cluster.addNode target_name

    deps = []
    for key,val of fnode.deps
      key = @conciseName key
      cluster.addEdge nn, key
      deps.push val

    @opt.completedJobs[target_name] = true

    # RECURSION
    @generate idx, cluster for idx in deps


exports.DumbTreePrinter = DumbTreePrinter
exports.MakefilePrinter = MakefilePrinter
exports.DotPrinter = DotPrinter
