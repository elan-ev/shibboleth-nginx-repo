#!/usr/bin/env bash

# If true, shibboleth nginx modules will be rebuild, regardles of aviability of the packages in repository.
_FORCE_REBUILD_SHIBBOLETH_MODULES="${FORCE_REBUILD_SHIBBOLETH_MODULES:-false}"

set -e
if [ -f "/repo/repodata/repomd.xml" ]
then
cat <<EOF > /etc/yum.repos.d/Shibboleth-Nginx.repo
[shibboleth-nginx]
name=Shibboleth Nginx packages - RHEL\$releasever
baseurl=file:///repo/
gpgcheck=1
gpgkey=https://elan-ev.github.io/shibboleth-nginx-repo/gpgkey.asc
enabled=1
EOF
else
    _FORCE_REBUILD_SHIBBOLETH_MODULES="true"
fi

rpm --import https://elan-ev.github.io/shibboleth-nginx-repo/gpgkey.asc
dnf install -y epel-release

__NGINX_VERSION="$(dnf repoquery -q --latest-limit 1 --qf '%{version}' nginx)"
__NGINX_MOD_SHIBBOLETH_VERSION="$(dnf repoquery -q --latest-limit 1 --qf '%{version}-%{release}' nginx-mod-http-shibboleth)"

case $__NGINX_MOD_SHIBBOLETH_VERSION in
*-$__NGINX_VERSION*)  __MODULE_EXISTS="true";;
*)                    __MODULE_EXISTS="false";;
esac

if [ "$_FORCE_REBUILD_SHIBBOLETH_MODULES" = "true" ] || [ "$__MODULE_EXISTS" = "false" ]
then
    sh /scripts/build-nginx-mods-dynamic.sh
else
    echo "Nginx Shibboleth module is up to date. Skip build."
fi
