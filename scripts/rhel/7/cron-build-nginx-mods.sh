#!/usr/bin/env bash

# If true, shibboleth nginx modules will be rebuild, regardles of aviability of the packages in repository.
_FORCE_REBUILD_SHIBBOLETH_MODULES="${FORCE_REBUILD_SHIBBOLETH_MODULES:-false}"

set -e
cat <<EOF > /etc/yum.repos.d/Shibboleth-Nginx.repo
[shibboleth-nginx]
name=Shibboleth Nginx packages - RHEL\$releasever
baseurl=file:///repo/
gpgcheck=1
gpgkey=https://elan-ev.github.io/shibboleth-nginx-repo/gpgkey.asc
enabled=1
EOF

rpm --import https://elan-ev.github.io/shibboleth-nginx-repo/gpgkey.asc
yum install -y epel-release yum-utils

__NGINX_VERSION="$(repoquery -q --qf '%{version}' nginx)"
__NGINX_MOD_SHIBBOLETH_VERSION="$(repoquery -q --qf '%{version}' nginx-mod-http-shibboleth)"

if [ -z "$__NGINX_MOD_SHIBBOLETH_VERSION" ] || [ "$__NGINX_VERSION" != "$__NGINX_MOD_SHIBBOLETH_VERSION" ] || [ "true" == "$_FORCE_REBUILD_SHIBBOLETH_MODULES" ]
then
    sh /scripts/build-nginx-mods.sh
else
    echo "Nginx Shibboleth module is up to date. Skip build."
fi
