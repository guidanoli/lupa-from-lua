#!/usr/bin/env bash

cd lupa
rm lupa/_lupa.c
python setup.py build
cd ..

source setuplupa.sh
