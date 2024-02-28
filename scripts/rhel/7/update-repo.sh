#!/usr/bin/env bash

# If true, the RPM repository will be recreated.
# If false or unset, only new packages will be added to the repository.
_FORCE_RECREATE_REPO="${FORCE_RECREATE_REPO:-false}"

set -e
yum install -y createrepo gpg

pushd /repo 2>/dev/null
if [ "true" == "$_FORCE_RECREATE_REPO" ]
then
    echo "Recreate RPM repository"
    createrepo .
else
    echo "Update RPM repository"
    createrepo --update .
fi

# sign package
if [ -z "$GPG_SIGNING_KEY" ]; then
    echo "No GPG key provided. This is ok, if you test the build. But IT SHOULD NEVER HAPPEN ON REGULAR BUILD! Skip signing RPM repository metadata."
else
    echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --import
    gpg --no-tty --batch --yes --detach-sign --armor repodata/repomd.xml
fi
popd 2>/dev/null

echo "RPM repository updated"