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

top: build _build/lib/javascript-parser.cma
	ocamlfind ocamlmktop -o $@ -package unix,yojson -linkpkg _build/lib/javascript-parser.cma
