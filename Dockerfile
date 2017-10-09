FROM conductor/openresty-ppc64le:1.9.15.1

RUN apt-get update -y;exit 0
RUN apt-get install -y libfindbin-libs-perl openssl luarocks git

RUN cd / && git clone https://github.com/Mashape/kong.git

RUN export PATH=$PATH:/opt/ibm/router/bin


RUN apt-get install -y libpcre3 libpcre3-dev vim zlib1g-dev libssl-dev libpq-dev libluajit-5.1-common

RUN luarocks install lsocket && \
luarocks install luasocket && luarocks install lua-resty-jit-uuid && luarocks install penlight && luarocks install lua_system_constants && \
luarocks install lua-resty-dns-client && luarocks install lua-resty-mediador && luarocks install version && luarocks install pgmoon && \
luarocks install luacrypto && luarocks install lua-log && luarocks install luasyslog && luarocks install lua_pack && \
luarocks install luatz && luarocks install  multipart && luarocks install lua-resty-iputils && luarocks install lua-resty-http && \
luarocks install luaossl CRYPTO_LIBDIR=/lib/powerpc64le-linux-gnu/ OPENSSL_LIBDIR=/lib/powerpc64le-linux-gnu/ && luarocks install lapis

RUN mkdir -p /opt/ibm/router/lualib/luarocks && \
cp -r /usr/share/lua/5.1/luarocks/* /opt/ibm/router/lualib/luarocks/ && \
mv /kong /usr/local/

RUN mkdir -p /usr/local/openresty/luajit/lib && cp -R /opt/ibm/router/luajit/lib /usr/local/openresty/luajit/lib

COPY openresty-1.11.2.4.tar.gz /

RUN export LUAJIT_LIB=/opt/ibm/router/luajit/lib && \
export LUAJIT_INC=/opt/ibm/router/luajit/include/luajit-2.1 && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/ibm/router/luajit/lib/

COPY Makefile2 /makefiletemp
COPY v2.1.0-alpha-ppc64el-rc2.tar.gz /v2.1.0-alpha-ppc64el-rc2.tar.gz
RUN tar -xzf v2.1.0-alpha-ppc64el-rc2.tar.gz 
RUN tar -zxf openresty-1.11.2.4.tar.gz 
RUN cd openresty-1.11.2.4/bundle && rm -rf LuaJIT-2.1-20170405/*  && \
	mv /LuaJIT-PPC64-2.1.0-alpha-ppc64el-rc2/* /openresty-1.11.2.4/bundle/LuaJIT-2.1-20170405
RUN ln -sf luajit-2.1.0-alpha /usr/local/bin/luajit
RUN cd openresty-1.11.2.4 && ./configure  \
--with-pcre-jit \
--with-ipv6 \
--with-http_realip_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_v2_module \
--with-luajit && \ 
make && make install

RUN cd /openresty-1.11.2.4/bundle/nginx-1.11.2/ && ./configure --prefix=/usr/local/openresty/nginx --with-cc-opt=-O2 --add-module=../ngx_devel_kit-0.3.0 --add-module=../echo-nginx-module-0.60 --add-module=../xss-nginx-module-0.05 --add-module=../ngx_coolkit-0.2rc3 --add-module=../set-misc-nginx-module-0.31 --add-module=../form-input-nginx-module-0.12 --add-module=../encrypted-session-nginx-module-0.06 --add-module=../srcache-nginx-module-0.31 --add-module=../ngx_lua-0.10.8 --add-module=../ngx_lua_upstream-0.06 --add-module=../headers-more-nginx-module-0.32 --add-module=../array-var-nginx-module-0.05 --add-module=../memc-nginx-module-0.18 --add-module=../redis2-nginx-module-0.14 --add-module=../redis-nginx-module-0.3.7 --add-module=../rds-json-nginx-module-0.14 --add-module=../rds-csv-nginx-module-0.07 --with-ld-opt=-Wl,-rpath,/usr/local/openresty/luajit/lib --with-pcre-jit --with-ipv6 --with-http_realip_module --with-http_ssl_module --with-http_stub_status_module --with-http_v2_module && \
cp /makefiletemp /openresty-1.11.2.4/bundle/nginx-1.11.2/objs/Makefile && \
make && make install

COPY dumb-init /usr/local/bin/dumb-init
RUN  chmod +x /usr/local/bin/dumb-init

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

WORKDIR /usr/local/kong

RUN cp -r /opt/ibm/router/lualib/resty/* /usr/local/share/lua/5.1/resty/

STOPSIGNAL SIGTERM
ENV PATH="/usr/local/nginx/sbin/:$PATH:/usr/local/kong:/usr/local/kong/bin:/opt/ibm/router/bin"
ENV LUA_PATH="./?.lua;/usr/share/lua/5.1/?.lua;/usr/share/lua/5.1/?/init.lua;/usr/local/share/lua/5.1/?.lua;/opt/ibm/router/lualib/resty/?.lua;/opt/ibm/router/lualib/resty/?/init.lua"
CMD ["kong", "start"]
#CMD ["/usr/local/nginx/sbin/nginx", "-c", "/usr/local/kong/nginx.conf", "-p", "/usr/local/kong/"]


