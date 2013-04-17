# make-commonjs-depend

Create dependencies for Makefiles. It's like
[makedepend(1)](http://www.xfree86.org/current/makedepend.1.html) but
for JavaScript.

## Features

* Looks for CommonJS `require` to build the dependency tree.
* Detects circular links.
* Parses each dependency exactly once, maintaining an internal symbol
  table for each.
* Ignores 'system' libs & libs from 'node_modules' directory.

## Installation

	$ npm install -g make-commonjs-depend

Don't forget to have CoffeeScript installed globally too:

    $ npm install -g coffee-script

## Examples

    $ make-commonjs-depend -h
    Usage: make-commonjs-depend [options] file.js ...

    Available options:
      -h, --help                output usage information & exit
      -V, --version             output the version number & exit
      -v, --verbose             increase a verbosity level (debug only)
      -o, --output [FILE]       write result to a FILE instead of stdout
      -p, --prefix [STRING]     the prefix is prepended to the name of the target
      -m, --mode [STRING]       makefile, tree-dumb, dot
          --dups-check          analyze any file exactly once
          --no-circular-error   skip circular nodes (not recommended)

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

### Just for fun result of dot rendering

    $ make-commonjs-depend *js -m dot | dot -Tpng | xv -

![options page](https://raw.github.com/gromnitsky/make-commonjs-depend/master/doc/simple.png)

    $ pwd
    /opt/s/node-v0.10.4-linux-x86/lib/node_modules/npm/lib
    $ find . -type f -name \*js | xargs make-commonjs-depend \
        -m dot --no-circular-error | dot -Tpng | xv -

![options page](https://raw.github.com/gromnitsky/make-commonjs-depend/master/doc/npm.png)

## BUGS

* Doesn't work under Windows.

## License

MIT.
