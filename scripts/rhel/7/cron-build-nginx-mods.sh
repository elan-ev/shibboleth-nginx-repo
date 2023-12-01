#!/usr/bin/env bash

# If true, shibboleth nginx modules will be rebuild, regardles of aviability of the packages in repository.
_FORCE_REBUILD_SHIBBOLETH_MODULES="${FORCE_REBUILD_SHIBBOLETH_MODULES:-false}"

set -e
cat <<EOF > /etc/yum.repos.d/Shibboleth-Nginx.repo
[shibboleth-nginx]
name=Shibboleth Nginx packages - RHEL\$releasever
baseurl=file:///repo/
gpgcheck=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1
EOF

yum install -y epel-release yum-utils

__NGINX_VERSION="$(repoquery -q --qf '%{version}' nginx)"
__NGINX_MOD_SHIBBOLETH_VERSION="$(repoquery -q --qf '%{version}' nginx-mod-http-shibboleth)"

if [ -z "$__NGINX_MOD_SHIBBOLETH_VERSION" ] || [ "$__NGINX_VERSION" != "$__NGINX_MOD_SHIBBOLETH_VERSION" ] || [ "true" == "$_FORCE_REBUILD_SHIBBOLETH_MODULES" ]
then
    sh /scripts/build-nginx-mods.sh
else
    echo "Nginx Shibboleth module is up to date. Skip build."
fi
