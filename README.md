# Lupa from Lua

Make sure to clone this repository recursively. If you forgot to, simply run `git submodule update --init --recursive`.

## Setup

You can compile `lupafromlua` with CMake:

```
[In the project root]
mkdir build
cd build
cmake ..
[Here, you can tweak CMakeCache.txt if the wrong Lua or Python versions were picked]
```

And you can install `lupa` with setuptools:

```
[In the project root]
git submodule update --init --recursive
cd lupa
pip install -r requirements.txt
python setup.py install
```

## Dependencies

* CMake >= 3.0
* Lua >= 5.0
* Python >= 3.5 with shared library [1]

[1] You can compile Python from source and pass --enable-shared to configure
