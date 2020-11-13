#!/usr/bin/env bash

pushd lupa
rm lupa/_lupa.c
python setup.py build --force
popd

libdir=$(find lupa -maxdepth 2 \
                   -type d \
		   -regex "lupa/build/lib.*");

export PYTHONPATH="$libdir"
