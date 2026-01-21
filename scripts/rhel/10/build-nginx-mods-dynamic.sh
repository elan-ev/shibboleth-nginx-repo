#!/usr/bin/env bash

_NGINX_MOD_HEADERS_MORE_VERSION="0.39"
_NGINX_MOD_SHIBBOLETH_VERSION="2.0.2"

set -e

# Install EPEL for nginx sources
dnf install -y epel-release

# install build environment
dnf install -y make gcc rpmdevtools rpm-sign gpg 'dnf-command(download)' sed wget

mkdir /build
pushd /build
NGINX_VERSION="$(dnf repoquery -q --latest-limit 1 --qf '%{version}' nginx)"
# install nginx build dependencies
dnf builddep -y nginx-$NGINX_VERSION
# download sources
wget -O - https://nginx.org/download/nginx-"$NGINX_VERSION".tar.gz | tar -xz
wget -O - https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v$_NGINX_MOD_HEADERS_MORE_VERSION.tar.gz | tar -xz
NGINX_MOD_HEADERS_MORE_PATH="$(readlink -f headers-more-nginx-module-$_NGINX_MOD_HEADERS_MORE_VERSION)"
wget -O - https://github.com/nginx-shib/nginx-http-shibboleth/archive/refs/tags/v"$_NGINX_MOD_SHIBBOLETH_VERSION".tar.gz | tar -xz
NGINX_MOD_SHIBBOLETH_PATH="$(readlink -f nginx-http-shibboleth-$_NGINX_MOD_SHIBBOLETH_VERSION)"
# build nginx modules
pushd /build/nginx-"$NGINX_VERSION"
./configure --with-compat --add-dynamic-module="$NGINX_MOD_HEADERS_MORE_PATH" --add-dynamic-module="$NGINX_MOD_SHIBBOLETH_PATH"
make modules
popd
# create rpms
rpmdev-setuptree
cat <<EOF > nginx-mod-http-headers-more-filter.spec
%global  nginx_abiversion $NGINX_VERSION
%global  headers_more_filter_module_version $_NGINX_MOD_HEADERS_MORE_VERSION
EOF
cat /scripts/nginx-mod-http-headers-more-filter.spec >> nginx-mod-http-headers-more-filter.spec
rpmbuild -bb nginx-mod-http-headers-more-filter.spec
cat <<EOF > nginx-mod-http-shibboleth.spec
%global  nginx_abiversion $NGINX_VERSION
%global  shibboleth_module_version $_NGINX_MOD_SHIBBOLETH_VERSION
EOF
cat /scripts/nginx-mod-http-shibboleth.spec >> nginx-mod-http-shibboleth.spec
rpmbuild -bb nginx-mod-http-shibboleth.spec
popd

# Sign package
if [ -z "$GPG_SIGNING_KEY" ]; then
    echo "No GPG key provided. This is ok, if you test the build. But IT SHOULD NEVER HAPPEN ON REGULAR BUILD! Skip signing RPM packages."
else
    GPG_NAME=$(echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --show-keys --with-colons | grep -m1 "uid:" | cut -d: -f10)
    echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --import
    echo "%_gpg_name $GPG_NAME" >> ~/.rpmmacros
    rpm --addsign \
        ~/rpmbuild/RPMS/x86_64/nginx-mod-http-headers-more-filter-$_NGINX_MOD_HEADERS_MORE_VERSION*.rpm \
        ~/rpmbuild/RPMS/x86_64/nginx-mod-http-shibboleth-$_NGINX_MOD_SHIBBOLETH_VERSION*.rpm
fi

# move rpms to repo directory
mv ~/rpmbuild/RPMS/x86_64/nginx-mod-http-headers-more-filter-$_NGINX_MOD_HEADERS_MORE_VERSION*.rpm /repo/
mv ~/rpmbuild/RPMS/x86_64/nginx-mod-http-shibboleth-$_NGINX_MOD_SHIBBOLETH_VERSION*.rpm /repo/