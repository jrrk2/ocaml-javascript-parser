.PHONY: build test clean

SETUP = ocaml setup.ml

build: setup.data
	$(SETUP) -build

setup.data: setup.ml
	$(SETUP) -configure --override is_native false

setup.ml: _oasis
	oasis setup

test:
	$(SETUP) -test

clean:
	$(SETUP) -distclean

top:
	ocamlmktop -o $@ unix.cma _build/lib/javascript-parser.cma
