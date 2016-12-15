FROM ubuntu

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    wget perl make build-essential procps \
    libreadline-dev libncurses5-dev libpcre3-dev libssl-dev \
 && rm -rf /var/lib/apt/lists/*
RUN groupadd -r nginx && useradd -r -g nginx nginx
RUN wget --no-check-certificate https://openresty.org/download/openresty-1.11.2.2.tar.gz && \
 wget --no-check-certificate https://www.openssl.org/source/openssl-1.0.2j.tar.gz && \
 tar -xzf openssl-1.0.2j.tar.gz && \
 tar -xzf openresty-1.11.2.2.tar.gz && \
 cd openresty-1.11.2.2 &&\
 ./configure --prefix=/opt/verynginx/openresty --user=nginx --group=nginx --with-http_v2_module --with-http_sub_module --with-http_stub_status_module --with-luajit --with-openssl=../openssl-1.0.2j &&\
 make && make install && cd .. && mkdir code

 COPY ./ code 
 RUN mkdir -p /opt/verynginx && cd code &&\
     cp -r -f ./verynginx /opt/verynginx &&\
     cp -f ./nginx.conf  /opt/verynginx/openresty/nginx/conf/ &&\
     chmod -R 777 /opt/verynginx/verynginx/configs

EXPOSE 80
VOLUME '/opt/verynginx/verynginx/configs'
VOLUME '/opt/verynginx/openresty/nginx/logs'
VOLUME '/opt/verynginx/openresty/nginx/conf'
VOLUME '/opt/verynginx/openresty/nginx/html'

CMD ["/opt/verynginx/openresty/nginx/sbin/nginx", "-g", "daemon off; error_log /dev/stderr info;"]
