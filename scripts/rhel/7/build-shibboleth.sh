#!/bin/sh

# Build a specific Shibboleth version by setting this variable or
# uncomment it to build latest available version.
#_SHIBBOLETH_VERSION="3.4.0"

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

# Accept Shibboleth's GPG keys
rpm --import https://shibboleth.net/downloads/service-provider/RPMS/repomd.xml.key
rpm --import https://shibboleth.net/downloads/service-provider/RPMS/cantor.repomd.xml.key

# Install EPEL for fcgi-devel
yum install -y epel-release

# Install required packages for building
yum install -y \
  make \
  rpm-build \
  rpmdevtools \
  rpm-sign gpg \
  fcgi-devel \
  sed \
  yum-utils

# Enable powertools repo for build dependency doxygen
#yum-config-manager --enable powertools

# Download Shibboleth sources
if [ "$_SHIBBOLETH_VERSION" ]; then
    yumdownloader --source "shibboleth-$_SHIBBOLETH_VERSION"
else
    yumdownloader --source shibboleth
fi

# Install Shibboleth sources
rpm -i shibboleth*.src.rpm && rm -f shibboleth*.src.rpm

# Install build dependencies
yum-builddep -y ~/rpmbuild/SPECS/shibboleth.spec

# Rename schibboleth package to shibboleth-fastcgi
sed -i 's_^Name:[ \t]*shibboleth$_Name: shibboleth-fastcgi_g' ~/rpmbuild/SPECS/shibboleth.spec
sed -i 's_^Obsoletes:[ \t]*shibboleth-sp = \(.*\)$_Obsoletes: shibboleth = %{version}\nObsoletes: shibboleth-sp = \1_g' ~/rpmbuild/SPECS/shibboleth.spec
sed -i 's_%{name}_shibboleth_g' ~/rpmbuild/SPECS/shibboleth.spec

# Build binary package from spec file with additional argument fastcgi
rpmbuild -bb ~/rpmbuild/SPECS/shibboleth.spec --with fastcgi

# Sign package
if [ -z "$GPG_SIGNING_KEY" ]; then
    echo "No GPG key provided. This is ok, if you test the build. But IT SHOULD NEVER HAPPEN ON REGULAR BUILD! Skip signing RPM package."
else
    GPG_NAME=$(echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --show-keys --with-colons | grep -m1 "uid:" | cut -d: -f10)
    echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --import
    echo "%_gpg_name $GPG_NAME" >> ~/.rpmmacros
    rpm --addsign ~/rpmbuild/RPMS/x86_64/shibboleth-fastcgi-[0-9]*.x86_64.rpm
fi

# Done
mv ~/rpmbuild/RPMS/x86_64/shibboleth-fastcgi-[0-9]*.x86_64.rpm /repo/