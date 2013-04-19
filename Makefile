JSON := json
MOCHA := node_modules/.bin/mocha
OPTS :=

.PHONY: clobber clean

all: test

node_modules: package.json
	npm install
	touch $@

test: compile
	$(MOCHA) --compilers coffee:coffee-script -u tdd test $(OPTS)

compile: node_modules

clean:

clobber: clean
	rm -rf node_modules

# Debug. Use 'gmake p-obj' to print $(obj) variable.
p-%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)
