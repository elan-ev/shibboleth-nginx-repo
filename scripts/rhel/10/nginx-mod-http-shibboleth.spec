
Name:                 nginx-mod-http-shibboleth
Version:              %{shibboleth_module_version}
Release:              %{nginx_abiversion}%{?dist}
Summary:              Shibboleth module for Nginx
License:              All rights reserved
URL:                  https://github.com/nginx-shib/nginx-http-shibboleth/
Requires:             nginx(abi) = %{nginx_abiversion}
Requires(post):       systemd

%description
%{summary}.

%install
install -p -m 0755 -d %{buildroot}%{_libdir}/nginx/modules %{buildroot}%{_datadir}/nginx/modules
install -p -m 0644 /build/nginx-%{nginx_abiversion}/objs/ngx_http_shibboleth_module.so %{buildroot}%{_libdir}/nginx/modules
echo 'load_module "%{_libdir}/nginx/modules/ngx_http_shibboleth_module.so";' \
    > %{buildroot}%{_datadir}/nginx/modules/%{name}.conf
install -p -m 0644 /build/nginx-http-shibboleth-%{shibboleth_module_version}/LICENSE %{_builddir}/LICENSE

%post
if [ $1 -eq 1 ]; then
    /usr/bin/systemctl reload nginx.service >/dev/null 2>&1 || :
fi

%files
%defattr(644, root, root, 755)
%{_libdir}/nginx/modules/ngx_http_shibboleth_module.so
%{_datadir}/nginx/modules/%{name}.conf
%license LICENSE

%changelog
* Tue Mar 19 2024 Waldemar Smirnow <smirnow@elan-ev.de> - 1.0
- Initial RPM package release
