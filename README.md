# Lupa from Lua

Make sure to clone this repository recursively:

```
[In the project root]
git submodule update --init --recursive
```

## Setup

You can compile `lupafromlua` with CMake:

```
[In the project root]
mkdir build
cd build
cmake ..
[Here, you can tweak CMakeCache.txt if the wrong Lua or Python versions were picked]
```

And you can install `lupa` with the bash script:

```
[In the project root]
source buildlupa.sh
```

## Dependencies

* CMake >= 3.0
* Lua >= 5.0
* Python >= 3.5 with shared library [1]
  * Python modules for Lupa: `pip install -r lupa/requirements.txt`

[1] You can compile Python from source and pass --enable-shared to configure
