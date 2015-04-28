#!/usr/bin/env bash

VERSION="0.10"
WORKING_DIR=`pwd`

git submodule update
cd shared/radicale && git checkout $VERSION
cd $WORKING_DIR && qbuild --exclude ".git"
