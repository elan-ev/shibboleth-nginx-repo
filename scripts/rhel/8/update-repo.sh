#!/usr/bin/env bash

dnf install -y createrepo

pushd /repo 2>/dev/null
createrepo --update .
popd 2>/dev/null