#!/usr/bin/env bash

yum install -y createrepo

pushd /repo 2>/dev/null
createrepo --update .
popd 2>/dev/null