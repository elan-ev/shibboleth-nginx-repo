#!/usr/bin/env bash

# If true, the RPM repository will be recreated.
# If false or unset, only new packages will be added to the repository.
_FORCE_RECREATE_REPO="${FORCE_RECREATE_REPO:-false}"

yum install -y createrepo

pushd /repo 2>/dev/null
if [ "true" == "$_FORCE_RECREATE_REPO" ]
then
    echo "Recreate RPM repository"
    createrepo .
else
    echo "Update RPM repository"
    createrepo --update .
fi
popd 2>/dev/null