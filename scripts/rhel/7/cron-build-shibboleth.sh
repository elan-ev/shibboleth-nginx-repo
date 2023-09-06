#!/usr/bin/env bash

set -e
# Install Shibboleth's recommended Service Provider repo as per
# https://shibboleth.net/downloads/service-provider/RPMS/
cat <<EOF > /etc/yum.repos.d/shibboleth.repo
[shibboleth]
name=Shibboleth (CentOS_7)
# Please report any problems to https://shibboleth.atlassian.net/jira
type=rpm-md
mirrorlist=https://shibboleth.net/cgi-bin/mirrorlist.cgi/CentOS_7
gpgcheck=1
gpgkey=https://shibboleth.net/downloads/service-provider/RPMS/repomd.xml.key
        https://shibboleth.net/downloads/service-provider/RPMS/cantor.repomd.xml.key
enabled=1
EOF

# Import Shibboleth's GPG keys
rpm --import https://shibboleth.net/downloads/service-provider/RPMS/repomd.xml.key
rpm --import https://shibboleth.net/downloads/service-provider/RPMS/cantor.repomd.xml.key

cat <<EOF > /etc/yum.repos.d/Shibboleth-Nginx.repo
[shibboleth-nginx]
name=Shibboleth Nginx packages - RHEL\$releasever
baseurl=file:///repo/
gpgcheck=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1
EOF

yum install -y epel-release yum-utils

__SHIBBOLETH_VERSION="$(repoquery -q --qf '%{version}' shibboleth)"
__SHIBBOLETH_FASTCGI_VERSION="$(repoquery -q --qf '%{version}' shibboleth-fastcgi)"

if [ -z "$__SHIBBOLETH_FASTCGI_VERSION" ] || [ "$__SHIBBOLETH_VERSION" != "$__SHIBBOLETH_FASTCGI_VERSION" ]
then
    sh /scripts/build-shibboleth.sh
else
    echo "Shibboleth is up to date. Skip build."
fi
