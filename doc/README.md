# make-commonjs-depend

Create dependencies for Makefiles. It's like
[makedepend(1)](http://www.xfree86.org/current/makedepend.1.html) but
for JavaScript.

## Features

* Look for CommonJS `require` to build the dependency tree (with
  substack's `detective` lib (which uses Esprima parser, not some crazy
  regexps)).
* Detects circular links.
* Parses each dependency exactly once, maintaining an internal symbol
  table for each.
* Ignores 'system' libs & libs from 'node_modules' directory.

## Examples

    $ make-commonjs-depend -h
    Usage: make-commonjs-depend [options] file.js ...

    Available options:
      -h, --help              output usage information & exit
      -V, --version           output the version number & exit
      -v, --verbose           increase a verbosity level (debug only)
      -o, --output [FILE]     write result to a FILE instead of stdout
      -p, --prefix [STRING]   the prefix is prepended to the name of the target
      -m, --mode [STRING]     makefile, tree-dumb, dot
          --dups-check        analyze any file exactly once

### Quick visual test

    $ make-commonjs-depend -m tree-dumb *js
    a.js, deps: 2
      b.js, deps: 1
        c.js, deps: 1
          d/d.js, deps: 0
      c.js, deps: 1
        d/d.js, deps: 0

    b.js, deps: 1
      c.js, deps: 1
        d/d.js, deps: 0

    c.js, deps: 1
      d/d.js, deps: 0

    d/d.js, deps: 0

### Output suitable for makefile

    $ make-commonjs-depend *js
    a.js: \
      b.js \
      c.js
    b.js: \
      c.js
    c.js: \
      d/d.js
    d/d.js:

Notice 0 duplication. Despite that input was 3 .js files, dependencies
were printed only once.

## Just for fun result of dot rendering

    $ make-commonjs-depend *js -m dot | dot -Tpng | xv -

![options page](https://raw.github.com/gromnitsky/make-commonjs-depend/master/doc/simple.png)

## Requirements

* Node.js >= 0.10.2
* CoffeeScript >= 1.6.2

## BUGS

* Doesn't work under Windows.

## TODO

* npm module

## License

MIT.
