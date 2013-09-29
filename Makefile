.PHONY: build test clean

SETUP = ocaml setup.ml

build: setup.data
	$(SETUP) -build

setup.data: setup.ml
	$(SETUP) -configure --enable-tests

setup.ml: _oasis
	oasis setup

test:
	$(SETUP) -test

clean:
	$(SETUP) -distclean

