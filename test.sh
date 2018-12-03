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
$TDIR/lint.sh
$TDIR/run-tests.sh
rm -rf $TDIR
