# pyproj

Creates template Python 3.6 projects with `yapf` and `mypy`.

## Other features
 * initialized project with simple docstrings and readme
 * initializes with an MIT license
 * sets up helper scripts to format and create files
 * lays out the following directory structure:
```
(14:16:08) | akalsi@archlinux | akalsi/code/pyproj (master)
$ tree -h foo/
foo/
├── [ 193]  create-file.sh
├── [4.0K]  foo
│   ├── [ 132]  __init__.py
│   └── [4.0K]  __pycache__
│       └── [ 264]  __init__.cpython-36.pyc
├── [ 377]  format.sh
├── [1.0K]  LICENSE.txt
├── [ 316]  README
├── [ 162]  setup.py
└── [4.0K]  test
    └── [  30]  __init__.py

3 directories, 8 files
```
 * adds a common sense `.gitignore`
 * adds files to a git repo if required without committing

## Usage
```
(14:14:16) | akalsi@archlinux | akalsi/code/pyproj (master)
$ ./create.sh -h
create.sh -d|--dir <dir> [-s|--use-setup]

Create a skelton Python 3 project

OPTIONS
  -d|--dir        Specify directory to set up project in
  -s|--use-setup  Create a setup.py file
  -h|--help       Show this message
```
