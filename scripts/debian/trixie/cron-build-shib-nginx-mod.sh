#!/usr/bin/env sh

# If true, shibboleth nginx modules will be rebuild, regardles of aviability of the packages in repository.
_FORCE_REBUILD_SHIBBOLETH_MODULES="${FORCE_REBUILD_SHIBBOLETH_MODULES:-false}"

cat <<EOF > /etc/apt/sources.list.d/nginx-mod-shibboleth.list
deb [allow-insecure=yes] file:///repo/ trixie non-free
EOF
apt update
__NGINX_VERSION="$(apt-cache show nginx | grep Version | sed 's/^Version: //' | cut -d- -f1)"
__NGINX_MOD_SHIBBOLETH_VERSION="$(apt-cache show libnginx-mod-http-shibboleth | grep Version | sed 's/^Version: //')"
case $__NGINX_MOD_SHIBBOLETH_VERSION in
"")                 __MODULE_EXISTS="false";;
$__NGINX_VERSION*)  __MODULE_EXISTS="true";;
*)                  __MODULE_EXISTS="false";;
esac
if  [ "$_FORCE_REBUILD_SHIBBOLETH_MODULES" = "true" ] || [ "$__MODULE_EXISTS" = "false" ]
then
    rm -f /etc/apt/sources.list.d/nginx-mod-shibboleth.list
    sh /scripts/build-shib-nginx-mod.sh
else
    echo "Nginx Shibboleth module is up to date. Skip build."
fi