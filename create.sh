#!/bin/bash

err() {
    >&2 echo E: create.sh: "$@"
    exit 1
}

show_help() {
    cat - > /dev/stdout <<EOF
create.sh -d|--dir <dir> [-s|--use-setup]

Create a skeleton Python 3 project with static typing support

OPTIONS
  -d|--dir        Specify directory to set up project in
  -s|--setup      Create a setup.py file
  -h|--help       Show this message

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]
    do
        key="$1"
        case "$key" in
            -h|--help)
                show_help
                shift
                exit 0
                ;;
            -d|--dir)
                wdir="$2"
                shift
                shift
                ;;
            -s|--setup)
                setup="1"
                shift
                ;;
            *)
                err "Unknown option '$1'"
                ;;
        esac
    done

    if [ "$wdir" = "" ];
    then
        show_help
        err "directory to setup not specified"
    fi
}

wdir=""
setup="0"
usegit="1"

test -n $(command -v python3) || err "Python 3 not installed or not in PATH"

py_ver=$(python3 -c "import sys; x=sys.version_info; print(x.major*10 + x.minor)")
if test "$py_ver" -lt 36; then
    err "Python 3.6 is the minimum requirement"
fi

parse_args "$@"

echo "using directory: $wdir"

if ! mkdir -p "$wdir";
then
    err "failed to make directory: $wdir"
fi

proj=$(cd "$wdir" && basename `pwd`)
echo "using project name: $proj"

if ! mkdir -p "$wdir/$proj";
then
    err "failed to make directory: $wdir/$proj"
fi

set -e

printf 'creating package __init__.py... '
cat - > "$wdir/$proj/__init__.py" <<EOF
"""
$proj


Init file for the '$proj' package.
"""
EOF

printf '[ok]\n'

if ! mkdir -p "$wdir/test";
then
    err "failed to make directory: $wdir/test"
fi


printf 'creating test __init__.py... '
cat - > "$wdir/test/__init__.py" <<EOF
"""
test

Test package for '$proj'.
"""

EOF

printf '[ok]\n'


printf "creating test/$proj/test_import.py... "
mkdir -p "$wdir/test/$proj"
cat - > "$wdir/test/$proj/test_import.py" <<EOF
"""
test.$proj.test_import

Verify the package is importable.
"""

def test_import():
    """Verify package is importable."""
    assert __import__('$proj') is not None

EOF

printf '[ok]\n'


printf 'creating LICENSE.txt for an MIT license... '
cat - > "$wdir/$proj/LICENSE.txt" <<EOF
MIT License

Copyright (c) `date +%Y` `git config --global user.name`

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

printf '[ok]\n'

printf 'creating py.typed file...'
touch "$wdir/$proj/py.typed"
printf '[ok]\n'

printf 'creating create-file.sh script... '
cat - <<EOF > "$wdir/create-file.sh"
#!/bin/bash

file="\$1"
dir=\$(dirname "\$0")
mkdir -p \$(dirname "\$file")

relpath=\$(echo "\$file" | sed 's+\$dir++g')
modname=\$(echo "\$relpath" | sed 's+/+.+g' | sed 's+\.py++g')

cat - <<EOM > "\$file"
"""
\$modname


PURPOSE:
"""

from typing import Any



EOM

mycd=\$(pwd)

# ensure __init__.py files everywhere
for p in \$(dirname \$file | sed 's|/| |g'); do
    cd \$p
    test -e ./__init__.py || touch ./__init__.py
done

cd \$mycd

bname=\$(basename \$file)
tfile="\$(dirname \$file)/test_\${bname}"

mkdir -p \$(dirname "test/\$tfile")
# ensure __init__.py files everywhere
for p in \$(dirname test/\$tfile | sed 's|/| |g'); do
    cd \$p
    test -e ./__init__.py || touch ./__init__.py
done

cd \$mycd

cat - <<EOM > "test/\$tfile"
"""
test.\$(echo \$tfile | sed 's|/|\.|g' | sed 's|\.py$||g')


PURPOSE: Tests for '\$(echo \$file | sed 's|/|\.|g' | sed 's|\.py$||g')'
"""

import \$(echo \$file | sed 's|/|\.|g' | sed 's|\.py$||g')


def test_empty():
    assert True

EOM
EOF

chmod u+x "$wdir/create-file.sh"
printf '[ok]\n'

printf 'creating run-tests.sh script... '
cat - <<EOF > "$wdir/run-tests.sh"
#!/bin/bash

file="\$1"
dir=\$(dirname "\$0")

cd "\$dir"

source .env/bin/activate
python3 -m pytest
deactivate
EOF

chmod u+x "$wdir/run-tests.sh"
printf '[ok]\n'

printf 'creating lint.sh file... '
cat - > "$wdir/lint.sh" <<EOF
#!/bin/bash

dir=\$(dirname "\$0")
proj=\$(basename \$(pwd))

cd "\$dir"

source .env/bin/activate

printf 'running black on source...\n'
find "\$proj" -name '*.py' | xargs -n1 -I{} bash -c "echo \" -> black {}\" && python3 -m black -l 79 {}"
if [ "\$?" != "0" ];
then
    printf '[failed]\n'
    exit 1
fi
printf '[ok]\n'

printf 'running mypy on source...\n'
find "\$proj" -name '*.py' | xargs -n1 -I{} bash -c "echo \" -> mypy {}\" && mypy {}"
if [ "\$?" != "0" ];
then
    printf '[failed]\n'
    exit 1
fi
printf '[ok]\n'

printf 'running black on tests...\n'
find "test" -name '*.py' | xargs -n1 -I{} bash -c "echo \" -> black {}\" && python3 -m black -l 79 {}"
if [ "\$?" != "0" ];
then
    printf '[failed]\n'
    exit 1
fi
printf '[ok]\n'

printf 'running mypy on tests...\n'
find "test" -name '*.py' | xargs -n1 -I{} bash -c "echo \" -> mypy {}\" && mypy {}"
if [ "\$?" != "0" ];
then
    printf '[failed]\n'
    exit 1
fi
printf '[ok]\n'


printf 'updating README... '
python3 -c 'import $proj; help($proj)' > README
printf '[ok]\n'

deactivate
EOF

chmod u+x "$wdir/lint.sh"
printf '[ok]\n'

if [ "$setup" = "1" ];
then
    printf 'creating setup.py... '
    cat - <<EOF > "$wdir/setup.py"
# setup for $proj

from distutils.core import setup
from setuptools import find_packages

packages = find_packages(where='.')
packages.remove('test')

print(f'Installing the following packages: {packages}')

install_requires=[]

with open('requirements.txt') as f:
    for line in f:
        line = line.strip()
        if line.startswith('#'):
            continue
        install_requires.append(line)

setup(
    name='$proj',
    version='0.1.dev0',
    package_dir={'$proj': '$proj'},
    package_data={'$proj': ['LICENSE.txt', 'py.typed']},
    packages=packages,
    install_requires=install_requires,
    long_description=open('README').read(),
    zip_safe=False)

EOF
    printf '[ok]\n'
fi

if [ "$usegit" = "1" ];
then
    printf 'intializing virtualenv and creating git repo... '
cat - > "$wdir/.gitignore" <<EOF
# gitignore for $proj

**/__pycache__
**/*.pyc
**/.mypy_cache
/MANIFEST
/dist/
/build/
/${proj}.egginfo/

# virtualenv additions
/.env/

# IDEs
/.idea/

EOF

  mkdir -p "$wdir/.github/workflows"
cat - > "$wdir/.github/workflows/tests.yml" <<EOF
name: CI

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop

jobs:
  build-linux-64:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: actions/setup-python@v2
      with:
        python-version: '3.x'
        architecture: 'x64'
    - name: Env setup
      run: |
        cd \$GITHUB_WORKSPACE
        python3 -m venv .env
        source .env/bin/activate
        python3 -m pip install -r requirements-dev.txt
    - name: Lint, mypy
      run: |
        cd \$GITHUB_WORKSPACE
        ./lint.sh
    - name: Tests
      run: |
        cd \$GITHUB_WORKSPACE
        ./run-tests.sh
EOF

    cd "$wdir"
    git init . 2>&1 > /dev/null
    if [ "$?" != "0" ];
    then
        printf '[failed]\n'
        exit 1
    fi
    git add .
    python3 -m venv .env > /dev/null
    source .env/bin/activate
    python3 -m pip install black mypy pytest setuptools > /dev/null
    echo "# Package production requirements" > requirements.txt
    echo "# Package development requirements" > requirements-dev.txt
    echo "-r requirements.txt" >> requirements-dev.txt
    python3 -m pip freeze >> requirements-dev.txt
    git add requirements*.txt
    ./lint.sh 2>&1 > /dev/null
    deactivate
    git add README
    printf '[all-ok]\n'
fi
