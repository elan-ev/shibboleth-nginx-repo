#!/usr/bin/env sh
_NGINX_MOD_SHIBBOLETH_VERSION="${NGINX_MOD_SHIBBOLETH_VERSION:-2.0.2}"
_PWD="$PWD"

set -e
apt update
apt install -y sed
sed -i 's/^Types: deb$/Types: deb deb-src/g' /etc/apt/sources.list.d/debian.sources
apt update
apt install -y dpkg-dev wget
apt build-dep -y nginx
mkdir /build
cd /build
NGINX_VERSION_FULL="$(apt show nginx | grep Version | sed 's/Version: //')"
NGINX_VERSION="$(echo $NGINX_VERSION_FULL | cut -d- -f1)"
wget https://nginx.org/download/nginx-"$NGINX_VERSION".tar.gz
tar xf "nginx-$NGINX_VERSION.tar.gz"
wget -O - https://github.com/nginx-shib/nginx-http-shibboleth/archive/refs/tags/v"$_NGINX_MOD_SHIBBOLETH_VERSION".tar.gz | tar -xz
NGINX_MOD_SHIBBOLETH_PATH="$(readlink -f nginx-http-shibboleth-$_NGINX_MOD_SHIBBOLETH_VERSION)"
cd nginx-"$NGINX_VERSION"
./configure --add-dynamic-module="$NGINX_MOD_SHIBBOLETH_PATH"
make modules
cd ..
PKG_ROOT="libnginx-mod-http-shibboleth_$NGINX_VERSION.$_NGINX_MOD_SHIBBOLETH_VERSION-1_amd64"
mkdir -p "$PKG_ROOT/usr/lib/nginx/modules" "$PKG_ROOT/usr/share/nginx/modules-available"
install -o root -g root -m 0644 -p nginx-"$NGINX_VERSION"/objs/ngx_http_shibboleth_module.so "$PKG_ROOT/usr/lib/nginx/modules/"
echo "load_module modules/ngx_http_shibboleth_module.so;" > mod-http-shibboleth.conf
install -o root -g root -m 0644 -p mod-http-shibboleth.conf "$PKG_ROOT/usr/share/nginx/modules-available/"
mkdir -p "$PKG_ROOT/DEBIAN"
cat <<EOF > "$PKG_ROOT/DEBIAN/control"
Package: libnginx-mod-http-shibboleth
Version: $NGINX_VERSION.$_NGINX_MOD_SHIBBOLETH_VERSION-1
Maintainer: ELAN e.V. <helpdesk@elan-ev.de>
Depends: nginx-common (>= $NGINX_VERSION)
Architecture: amd64
Homepage: https://github.com/nginx-shib/nginx-http-shibboleth
Description: Shibboleth auth request module for Nginx
EOF
dpkg --build "$PKG_ROOT"
echo "Build package complete"
#echo "Package metadata:"
#dpkg-deb --info "$PKG_ROOT.deb"
mkdir -p /repo/pool/non-free
cp -f "$PKG_ROOT.deb" /repo/pool/non-free/
cd "$_PWD"
