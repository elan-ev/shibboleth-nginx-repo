#!/usr/bin/env sh
_NGINX_MOD_SHIBBOLETH_VERSION="${NGINX_MOD_SHIBBOLETH_VERSION:-2.0.2}"
_PWD="$PWD"

set -e
apt update
DEBIAN_FRONTEND=noninteractive apt install -y tzdata
apt install -y sed
sed -i 's/^#\s*deb-src/deb-src/g' /etc/apt/sources.list
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
./configure --with-compat --add-dynamic-module="$NGINX_MOD_SHIBBOLETH_PATH"
make modules
cd ..
PKG_ROOT="libnginx-mod-http-shibboleth_$NGINX_VERSION.$_NGINX_MOD_SHIBBOLETH_VERSION-1_amd64"
mkdir -p "$PKG_ROOT/usr/lib/nginx/modules" "$PKG_ROOT/usr/share/nginx/modules-available"
install -o root -g root -m 0644 -p nginx-"$NGINX_VERSION"/objs/ngx_http_shibboleth_module.so "$PKG_ROOT/usr/lib/nginx/modules/"
echo "load_module modules/ngx_http_shibboleth_module.so;" > mod-http-shibboleth.conf
install -o root -g root -m 0644 -p mod-http-shibboleth.conf "$PKG_ROOT/usr/share/nginx/modules-available/"
mkdir -p "$PKG_ROOT/usr/share/doc/libnginx-mod-http-shibboleth/"
cat <<-EOF > "$PKG_ROOT/usr/share/doc/libnginx-mod-http-shibboleth/copyright"
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: nginx-http-shibboleth
Upstream-Contact: David Beitey
 Luca Bruno
Source: https://github.com/nginx-shib/nginx-http-shibboleth

Files: *
Copyright: 2013-present, David Beitey (davidjb)
 2014, Luca Bruno
License: All rights reserved

License: All rights reserved

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
EOF
chmod 0644 "$PKG_ROOT/usr/share/doc/libnginx-mod-http-shibboleth/copyright"
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
install -o root -g root -m 0755 -p /scripts/postinst /scripts/postrm "$PKG_ROOT/DEBIAN/"
dpkg --build "$PKG_ROOT"
echo "Build package complete"
#echo "Package metadata:"
#dpkg-deb --info "$PKG_ROOT.deb"
mkdir -p /repo/pool/multiverse
cp -f "$PKG_ROOT.deb" /repo/pool/multiverse/
cd "$_PWD"
