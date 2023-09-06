#!/usr/bin/env bash

set -e
cat <<EOF > /etc/yum.repos.d/Shibboleth-Nginx.repo
[shibboleth-nginx]
name=Shibboleth Nginx packages - RHEL\$releasever
baseurl=file:///repo/
gpgcheck=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-8
enabled=1
EOF

dnf install -y epel-release

__NGINX_VERSION="$(dnf repoquery -q --latest-limit 1 --qf '%{version}' nginx)"
__NGINX_MOD_SHIBBOLETH_VERSION="$(dnf repoquery -q --latest-limit 1 --qf '%{version}' nginx-mod-http-shibboleth)"

if [ -z "$__NGINX_MOD_SHIBBOLETH_VERSION" ] || [ "$__NGINX_VERSION" != "$__NGINX_MOD_SHIBBOLETH_VERSION" ]
then
    sh /scripts/build-nginx-mods.sh
else
    echo "Nginx Shibboleth module is up to date. Skip build."
fi
