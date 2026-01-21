#!/usr/bin/env bash

# If true, shibboleth will be rebuild, regardles of aviability of the package in repository.
_FORCE_REBUILD_SHIBBOLETH="${FORCE_REBUILD_SHIBBOLETH:-false}"

set -e
# Install Shibboleth's recommended Service Provider repo as per
# https://shibboleth.net/downloads/service-provider/RPMS/
cat <<EOF > /etc/yum.repos.d/shibboleth.repo
[shibboleth]
name=Shibboleth (rockylinux9)
# Please report any problems to https://shibboleth.atlassian.net/jira
type=rpm-md
mirrorlist=https://shibboleth.net/cgi-bin/mirrorlist.cgi/rockylinux10
gpgcheck=1
gpgkey=https://shibboleth.net/downloads/service-provider/RPMS/repomd.xml.key
        https://shibboleth.net/downloads/service-provider/RPMS/cantor.repomd.xml.key
enabled=1
EOF

# Import Shibboleth's GPG keys
rpm --import https://shibboleth.net/downloads/service-provider/RPMS/repomd.xml.key
rpm --import https://shibboleth.net/downloads/service-provider/RPMS/cantor.repomd.xml.key

if [ -f "/repo/repodata/repomd.xml" ]; then
cat <<EOF > /etc/yum.repos.d/Shibboleth-Nginx.repo
[shibboleth-nginx]
name=Shibboleth Nginx packages - RHEL\$releasever
baseurl=file:///repo/
gpgcheck=1
gpgkey=https://elan-ev.github.io/shibboleth-nginx-repo/gpgkey.asc
enabled=1
EOF
else
    _FORCE_REBUILD_SHIBBOLETH="true"
fi

rpm --import https://elan-ev.github.io/shibboleth-nginx-repo/gpgkey.asc
dnf install -y epel-release

__SHIBBOLETH_VERSION="$(dnf repoquery -q --latest-limit 1 --qf '%{version}' shibboleth)"
__SHIBBOLETH_FASTCGI_VERSION="$(dnf repoquery -q --latest-limit 1 --qf '%{version}' shibboleth-fastcgi)"

if [ -z "$__SHIBBOLETH_FASTCGI_VERSION" ] || [ "$__SHIBBOLETH_VERSION" != "$__SHIBBOLETH_FASTCGI_VERSION" ] || [ "true" == "$_FORCE_REBUILD_SHIBBOLETH" ]
then
    sh /scripts/build-shibboleth.sh
else
    echo "Shibboleth is up to date. Skip build."
fi
