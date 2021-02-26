# Prints Python extension module files suffix

from __future__ import print_function, absolute_import
from sys import exit

ext_suffix = None
try:
    import importlib.machinery
    ext_suffixes = importlib.machinery.EXTENSION_SUFFIXES
except ImportError:
    import imp
    ext_suffixes = [modtype[0] for modtype in imp.get_suffixes() if modtype[2] == imp.C_EXTENSION]

# Heuristic: get longest extension suffix

ext_suffix = max(ext_suffixes, key=len)

# If none of these configuration variables are set,
# we can only throw an error

if ext_suffix is None:
    exit(1)

print(ext_suffix, end='')
