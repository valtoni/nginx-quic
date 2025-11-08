ARG ALPINE_VERSION=3.22
ARG NGINX_VERSION=1.29.3
ARG QUICTLS_REF=openssl-3.1.5+quic1

FROM alpine:${ALPINE_VERSION} AS build

ARG NGINX_VERSION
ARG QUICTLS_REF
ENV NGINX_VERSION=${NGINX_VERSION}

RUN apk add --no-cache build-base pcre2-dev zlib-dev git cmake go curl perl linux-headers && \
    mkdir -p /build && cd /build && \
    git clone --depth=1 -b release-"${NGINX_VERSION}" https://github.com/nginx/nginx.git && \
    git clone --depth=1 -b "${QUICTLS_REF}" https://github.com/quictls/openssl.git quictls && \
    cd nginx && ./auto/configure \
      --prefix=/usr/share/nginx \
      --sbin-path=/usr/sbin/nginx \
      --conf-path=/etc/nginx/nginx.conf \
      --pid-path=/var/run/nginx.pid \
      --with-http_ssl_module \
      --with-http_v2_module \
      --with-http_v3_module \
      --with-stream=dynamic \
      --with-openssl=/build/quictls \
      --with-openssl-opt=enable-quic && \
    make && make install

FROM alpine:${ALPINE_VERSION} AS runtime

RUN apk add --no-cache pcre2 zlib && \
    mkdir -p /var/cache/nginx /var/log/nginx

COPY --from=build /usr/sbin/nginx /usr/sbin/nginx
COPY --from=build /usr/share/nginx /usr/share/nginx
COPY --from=build /usr/lib/nginx /usr/lib/nginx
COPY --from=build /etc/nginx /etc/nginx

RUN adduser -D -g 'nginx' nginx
USER nginx
EXPOSE 80 443/udp 443
CMD ["nginx", "-g", "daemon off;"]
