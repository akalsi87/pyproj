#!/usr/bin/env bash

TDIR=spam

cleanup() {
    rv=$?
    rm -rf "$TDIR"
    exit $rv
}

trap "cleanup" INT TERM EXIT

set -e

./create.sh -d $TDIR -s

cd $TDIR
./create-file.sh $TDIR/foo.py
./create-file.sh $TDIR/bar/baz.py
./lint.sh
./run-tests.sh
cd ../

rm -rf $TDIR
