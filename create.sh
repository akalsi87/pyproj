#!/usr/bin/env bash

err() {
    >&2 echo create.sh: "$@"
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
"""
test

$proj tests package
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

printf 'creating .style.yapf file...'
cat - <<EOF > "$wdir/.style.yapf"
[style]
based_on_style=pep8
spaces_before_comment=4
split_before_logical_operator=False
column_limit=80
allow_split_before_dict_value=False
join_multiple_lines=False
split_before_first_argument=False
split_before_named_assigns=True
each_dict_entry_on_separate_line=True
EOF
printf '[ok]\n'

printf 'creating create-file.sh script... '
cat - <<EOF > "$wdir/create-file.sh"
#!/usr/bin/env bash

file="\$1"
dir=\$(dirname "\$0")
mkdir -p \$(dirname "\$file")

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
\$(echo \$tfile | sed 's|/|\.|g' | sed 's|\.py$||g')

Tests for '\$(echo \$file | sed 's|/|\.|g' | sed 's|\.py$||g')'.
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
#!/usr/bin/env bash

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
#!/usr/bin/env bash

dir=\$(dirname "\$0")
proj=\$(basename \$(pwd))

cd "\$dir"

source .env/bin/activate

printf 'running yapf on source...\n'
find "\$proj" -name '*.py' | xargs -n1 -I{} bash -c "echo \" -> yapf {}\" && python3 -m yapf -i {}"
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

printf 'running yapf on tests...\n'
find "test" -name '*.py' | xargs -n1 -I{} bash -c "echo \" -> yapf {}\" && python3 -m yapf -i {}"
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
MANIFEST
dist/

# virtualenv additions
.env/

# IDEs
.idea/

EOF
    cd "$wdir"
    git init . 2>&1 > /dev/null
    if [ "$?" != "0" ];
    then
        printf '[failed]\n'
        exit 1
    fi
    git add .
    virtualenv .env > /dev/null
    source .env/bin/activate
    pip install mypy > /dev/null
    pip install yapf > /dev/null
    pip install pytest > /dev/null
    pip install setuptools > /dev/null
    pip freeze > requirements.txt
    git add requirements.txt
    ./lint.sh 2>&1 > /dev/null
    deactivate
    git add README
    printf '[all-ok]\n'
fi
