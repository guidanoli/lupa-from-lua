#!/usr/bin/env bash

cd lupa
rm -f lupa/_lupa.c
pip install -r requirements.txt
python setup.py build
cd ..