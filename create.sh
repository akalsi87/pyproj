#!/usr/bin/env bash

err() {
    >&2 echo create.sh: "$@"
    exit 1
}

show_help() {
    cat - > /dev/stdout <<EOF
create.sh -d|--dir <dir> [-s|--use-setup] [-g|--git]

Create a skelton Python 3 project

OPTIONS
  -d|--dir        Specify directory to set up project in
  -s|--use-setup  Create a setup.py file
  -g|--git        Set up a git repository
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
            -s|--use-setup)
                setup="1"
                shift
                ;;
            -g|--git)
                usegit="1"
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
usegit="0"

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

printf 'creating package __init__.py... '
cat - > "$wdir/$proj/__init__.py" <<EOF
"""
One-liner

Summary
- - - -

A summary...


Details
- - - -

Many more
details follow
here...

Usage
- - -

Examples here..

"""

EOF

printf '[ok]\n'

if ! mkdir -p "$wdir/test";
then
    err "failed to make directory: $wdir/test"
fi


printf 'creating test __init__.py... '
cat - > "$wdir/test/__init__.py" <<EOF
# __init__.py

#
# $proj test
#


EOF

printf '[ok]\n'


printf 'creating test/test_import.py... '
cat - > "$wdir/test/test_import.py" <<EOF
# test_import.py

import unittest

class TestCase(unittest.TestCase):
    def test_import(self):
        """Verify the package imports correctly."""
        pkg = __import__('$proj')
        self.assertIsNotNone(pkg)


EOF

printf '[ok]\n'


printf 'creating LICENSE.txt for an MIT license... '
cat - > "$wdir/LICENSE.txt" <<EOF
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

printf 'creating create-file.sh script... '
cat - <<EOF > "$wdir/create-file.sh"
#!/usr/bin/env bash

file="\$1"
dir=\$(dirname "\$0")

relpath=\$(echo "\$file" | sed 's+\$dir++g')
modname=\$(echo "\$relpath" | sed 's+/+.+g' | sed 's+\.py++g')

cat - <<EOM > "\$file"
"""
\$modname

Description...

FUNCTIONS:
    a: something

CLASSES:
    b: something

USAGE:
    ...

"""

import typing


EOM
EOF

chmod u+x "$wdir/create-file.sh"

printf 'creating test.sh script... '
cat - <<EOF > "$wdir/test.sh"
#!/usr/bin/env bash

file="\$1"
dir=\$(dirname "\$0")

cd "\$dir"
python3 -m unittest

EOF

chmod u+x "$wdir/test.sh"
printf '[ok]\n'

printf 'creating format.sh file... '
cat - > "$wdir/format.sh" <<EOF
#!/usr/bin/env bash

file="$1"
dir=$(dirname "$0")

cd "$dir"

printf 'running yapf... '
python3 -m yapf -ir .
printf '[ok]\n'

printf 'running mypy...\n'
find . -name '*.py' | xargs -n1 -I{} bash -c "echo {} && mypy {}"
if [ "$?" != "0" ];
then
    printf '[failed]\n'
    exit 1
fi
printf '[ok]\n'


printf 'updating README... '
python3 -c 'import $proj; help($proj)' > README
printf '[ok]\n'

EOF

chmod u+x "$wdir/format.sh"
printf '[ok]\n'

if [ "$setup" = "1" ];
then
    printf 'creating setup.py... '
    cat - <<EOF > "$wdir/setup.py"
# setup for $proj

from distutils.core import setup

setup(
    name='$proj',
    version='0.1dev',
    packages=['$proj'],
    license='MIT',
    long_description=''
)

EOF
    printf '[ok]\n'
fi

if [ "$usegit" = "1" ];
then
    printf 'intializing and adding git repo... '
cat - > "$wdir/.gitignore" <<EOF
# gitignore for $proj

**/__pycache__
**/*.pyc
**/.mypy_cache
MANIFEST
dist/

EOF
    cd "$wdir"
    git init . 2>&1 > /dev/null
    if [ "$?" != "0" ];
    then
        printf '[failed]\n'
        exit 1
    fi
    ./format.sh
    git add .
    printf '[ok]\n'
fi
