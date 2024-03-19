#!/usr/bin/env bash

set -e
if [ -z "$GPG_SIGNING_KEY" ]; then
    echo "No GPG key provided. This is ok, if you test the build. But IT SHOULD NEVER HAPPEN ON REGULAR BUILD! Skip signing RPM package."
    exit 1
fi
if [ ! -f /repo/repodata/repomd.xml ]; then
    echo "No RPM repository bound. Skip signing RPM repository."
    exit 1
fi
dnf install -y gpg rpm-sign
GPG_NAME=$(echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --show-keys --with-colons | grep -m1 "uid:u" | cut -d: -f10)
echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --import
echo "%_gpg_name $GPG_NAME" >> ~/.rpmmacros
rpm --addsign /repo/*.rpm
gpg --no-tty --batch --yes --detach-sign --armor /repo/repodata/repomd.xml
