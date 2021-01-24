# Prints Python extension module files suffix

from __future__ import print_function
from sys import exit
from sysconfig import get_config_var

# 'SO' has been deprecated and replaced by 'EXT_SUFFIX'
# For older versions of Python, 'EXT_SUFFIX' maps to None,
# falling back to the older 'SO'.

ext_suffix = get_config_var('EXT_SUFFIX') or \
             get_config_var('SO')

# If none of these configuration variables are set,
# we can only throw an error

if ext_suffix is None:
    exit(1)

print(ext_suffix, end='')
