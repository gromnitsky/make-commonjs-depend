class PrinterError extends Error
  constructor: (msg) ->
    @name = @constructor.name
    @message = "Printer: #{msg}"
    Error.captureStackTrace this, @name

# Abstract
class Printer

  constructor: (ftree) ->
    throw new PrinterError 'invalid tree' unless ftree?.root
    @tree = ftree.root

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

    name = fnode.name.replace (new RegExp "^#{process.cwd()}/?"), ''
    console.log "#{prefix}#{name}, deps: #{fnode.depSize()}"
    for key,val of fnode.deps
      @print val, indent+DumbTreePrinter.INDENT_STEP


exports.DumbTreePrinter = DumbTreePrinter
