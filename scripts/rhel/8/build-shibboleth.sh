#!/bin/sh

# Build a specific Shibboleth version by setting this variable or
# uncomment it to build latest available version.
#_SHIBBOLETH_VERSION="3.4.0"

set -e

# Install Shibboleth's recommended Service Provider repo as per
# https://shibboleth.net/downloads/service-provider/RPMS/
cat <<EOF > /etc/yum.repos.d/shibboleth.repo
[shibboleth]
name=Shibboleth (CentOS_8)
# Please report any problems to https://shibboleth.atlassian.net/jira
type=rpm-md
mirrorlist=https://shibboleth.net/cgi-bin/mirrorlist.cgi/CentOS_8
gpgcheck=1
gpgkey=https://shibboleth.net/downloads/service-provider/RPMS/repomd.xml.key
        https://shibboleth.net/downloads/service-provider/RPMS/cantor.repomd.xml.key
enabled=1
EOF

# Accept Shibboleth's GPG keys
rpm --import https://shibboleth.net/downloads/service-provider/RPMS/repomd.xml.key
rpm --import https://shibboleth.net/downloads/service-provider/RPMS/cantor.repomd.xml.key

# Install EPEL for fcgi-devel
dnf install -y epel-release

# Install required packages for building
dnf install -y \
  make \
  rpm-build \
  rpmdevtools \
  rpm-sign gpg \
  'dnf-command(config-manager)' \
  'dnf-command(download)' \
  'dnf-command(builddep)' \
  fcgi-devel \
  sed

# Enable powertools repo for build dependency doxygen
dnf config-manager --enable powertools

# Download Shibboleth sources
if [ "$_SHIBBOLETH_VERSION" ]; then
    dnf download --source "shibboleth-$_SHIBBOLETH_VERSION"
else
    dnf download --source shibboleth
fi

# Install Shibboleth sources
rpm -i shibboleth*.src.rpm && rm -f shibboleth*.src.rpm

# Install build dependencies
dnf builddep -y ~/rpmbuild/SPECS/shibboleth.spec

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
    echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --import
    GPG_NAME="$(gpg --list-secret-keys | grep uid | sed 's/uid[ ]*//')"
    echo "%_gpg_name $GPG_NAME" >> ~/.rpmmacros
    rpm --addsign ~/rpmbuild/RPMS/x86_64/shibboleth-fastcgi-[0-9]*.x86_64.rpm
fi

# Done
mv ~/rpmbuild/RPMS/x86_64/shibboleth-fastcgi-[0-9]*.x86_64.rpm /repo/