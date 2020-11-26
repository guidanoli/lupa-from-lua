#!/usr/bin/env bash

libdir=$(find lupa -maxdepth 2 \
                   -type d \
                   -regex "lupa/build/lib.*");

export PYTHONPATH="$libdir"
