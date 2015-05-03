#!/usr/bin/env bash

RADICALE_VERSION="0.10"
BOTTLE_VERSION="0.12.8"
WORKING_DIR=`pwd`

git submodule update
cd shared/lib/radicale && git checkout $RADICALE_VERSION
cd $WORKING_DIR
cd shared/lib/bottle && git checkout $BOTTLE_VERSION
cd $WORKING_DIR && qbuild --exclude ".git" --exclude ".pyc"
