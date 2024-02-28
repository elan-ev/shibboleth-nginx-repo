#!/bin/sh

_NGINX_HEADERS_MORE_VERSION="0.34"
_NGINX_SHIBBOLETH_VERSION="2.0.2"

set -e

# Install EPEL for nginx sources
dnf install -y epel-release

# install build environment and sownload sources
dnf install -y make gcc rpmdevtools rpm-sign gpg 'dnf-command(download)' sed
dnf download --source nginx
dnf builddep -y nginx-*.src.rpm
rpm --install nginx-*.src.rpm

# patch nginx spec file to build shibboleth module too
echo "%global  headers_more_filter_module_version $_NGINX_HEADERS_MORE_VERSION" > ~/rpmbuild/SPECS/nginx.spec.tmp
echo "%global  http_shibboleth_module_version $_NGINX_SHIBBOLETH_VERSION" >> ~/rpmbuild/SPECS/nginx.spec.tmp
cat ~/rpmbuild/SPECS/nginx.spec >> ~/rpmbuild/SPECS/nginx.spec.tmp
mv -f ~/rpmbuild/SPECS/nginx.spec.tmp ~/rpmbuild/SPECS/nginx.spec

sed -i 's|^Source210:\([ \t]*\)\(.*\)$|Source210:\1\2\nSource900:\1https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v%{headers_more_filter_module_version}.tar.gz\nSource901:\1https://github.com/nginx-shib/nginx-http-shibboleth/archive/refs/tags/v%{http_shibboleth_module_version}.tar.gz|g' ~/rpmbuild/SPECS/nginx.spec
sed -i 's|^%setup\(.*\)$|%setup\1 -b 900 -b 901|g' ~/rpmbuild/SPECS/nginx.spec
sed -i 's|^%prep|%package mod-http-headers-more-filter\nGroup: System Environment/Daemons\nSummary: Nginx headers more filters module\nRequires: nginx\n\n%description mod-http-headers-more-filter\n%{summary}.\n\n%package mod-http-shibboleth\nGroup: System Environment/Daemons\nSummary: Nginx shibboleth module\nRequires: nginx\nRequires: nginx-mod-http-headers-more-filter = %{epoch}:%{version}-%{release}\n\n%description mod-http-shibboleth\n%{summary}.\n\n%prep|g' ~/rpmbuild/SPECS/nginx.spec
sed -i 's|^\([ \t]*\)--with-debug\([ ]*[\]*\)$|\1--add-dynamic-module=../nginx-http-shibboleth-%{http_shibboleth_module_version} \\\n\1--add-dynamic-module=../headers-more-nginx-module-%{headers_more_filter_module_version} \\\n\1--with-debug\2|g' ~/rpmbuild/SPECS/nginx.spec
sed -i 's|^\([ \t]*\)> %{buildroot}%{_datadir}/nginx/modules/mod-stream.conf$|\1> %{buildroot}%{_datadir}/nginx/modules/mod-stream.conf\necho '\''load_module "%{_libdir}/nginx/modules/ngx_http_headers_more_filter_module.so";'\'' \\\n\1> %{buildroot}%{_datadir}/nginx/modules/mod-http-headers-more-filter.conf\necho '\''load_module "%{_libdir}/nginx/modules/ngx_http_shibboleth_module.so";'\'' \\\n\1> %{buildroot}%{_datadir}/nginx/modules/mod-http-shibboleth.conf|g' ~/rpmbuild/SPECS/nginx.spec
sed -i 's_^%preun_%post mod-http-headers-more-filter\nif [ $1 -eq 1 ]; then\n    /usr/bin/systemctl reload nginx.service >/dev/null 2>\&1 || :\nfi\n\n%post mod-http-shibboleth\nif [ $1 -eq 1 ]; then\n    /usr/bin/systemctl reload nginx.service >/dev/null 2>\&1 || :\nfi\n\n%preun_g' ~/rpmbuild/SPECS/nginx.spec
sed -i 's|^%{_libdir}/nginx/modules/ngx_stream_module.so$|%{_libdir}/nginx/modules/ngx_stream_module.so\n\n%files mod-http-headers-more-filter\n%{_datadir}/nginx/modules/mod-http-headers-more-filter.conf\n%{_libdir}/nginx/modules/ngx_http_headers_more_filter_module.so\n\n%files mod-http-shibboleth\n%{_datadir}/nginx/modules/mod-http-shibboleth.conf\n%{_libdir}/nginx/modules/ngx_http_shibboleth_module.so|g' ~/rpmbuild/SPECS/nginx.spec

# build nginx with modules
rpmbuild --undefine=_disable_source_fetch -bb ~/rpmbuild/SPECS/nginx.spec

# sign package
if [ -z "$GPG_SIGNING_KEY" ]; then
    echo "No GPG key provided. This is ok, if you test the build. But IT SHOULD NEVER HAPPEN ON REGULAR BUILD! Skip signing RPM package."
else
    echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --import
    GPG_NAME="$(gpg --list-secret-keys | grep uid | sed 's/uid[ ]*\[.*\] //')"
    echo "%_gpg_name $GPG_NAME" >> ~/.rpmmacros
    rpm --addsign \
        ~/rpmbuild/RPMS/x86_64/nginx-mod-http-headers-more-filter-[0-9]*.el8.x86_64.rpm \
        ~/rpmbuild/RPMS/x86_64/nginx-mod-http-shibboleth-[0-9]*.el8.x86_64.rpm
fi

# update repo
mv ~/rpmbuild/RPMS/x86_64/nginx-mod-http-headers-more-filter-[0-9]*.el8.x86_64.rpm /repo/
mv ~/rpmbuild/RPMS/x86_64/nginx-mod-http-shibboleth-[0-9]*.el8.x86_64.rpm /repo/