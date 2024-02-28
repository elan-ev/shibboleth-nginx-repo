#!/bin/env bash

set -e
if [ -z "$GPG_SIGNING_KEY" ]; then
    echo "No GPG key provided. This is ok, if you test the build. But IT SHOULD NEVER HAPPEN ON REGULAR BUILD! Skip signing RPM package."
    exit 1
fi
dnf install -y gpg rpm-sign
echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --import
GPG_NAME="$(gpg --list-secret-keys | grep uid | sed 's/uid[ ]*\[.*\] //')"
echo "%_gpg_name $GPG_NAME" >> ~/.rpmmacros
rpm --addsign /repo/*.rpm
gpg --no-tty --batch --yes --detach-sign --armor /repo/repodata/repomd.xml
