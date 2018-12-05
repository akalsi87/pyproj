#!/usr/bin/env bash

TDIR=spam

cleanup() {
    rv=$?
    rm -rf "$TDIR"
    exit $rv
}

trap "cleanup" INT TERM EXIT

set -e

./create.sh -d $TDIR -s -g

cd $TDIR
./lint.sh
./run-tests.sh
cd ../

rm -rf $TDIR
