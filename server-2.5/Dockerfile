FROM stoneage-base:i386

# buster 已归档；同时把运行时库降级到归档索引里与 -dev 包匹配的版本
RUN printf 'deb http://archive.debian.org/debian buster main\n' > /etc/apt/sources.list \
 && apt-get -o Acquire::Check-Valid-Until=false update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-downgrades \
      libc6=2.28-10+deb10u1 \
      libc6-dev=2.28-10+deb10u1 \
      libc-bin=2.28-10+deb10u1 \
      zlib1g=1:1.2.11.dfsg-1+deb10u1 \
      zlib1g-dev=1:1.2.11.dfsg-1+deb10u1 \
      libgnutls30=3.6.7-4+deb10u8 \
      libgnutls28-dev=3.6.7-4+deb10u8 \
      libgnutls-dane0=3.6.7-4+deb10u8 \
      libgnutls-openssl27=3.6.7-4+deb10u8 \
      libgnutlsxx28=3.6.7-4+deb10u8 \
      libtasn1-6=4.13-3 \
      libtasn1-6-dev=4.13-3 \
      libmariadb-dev \
      gcc make binutils perl bash \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ./ /app/

# 2.5 的访问器是 gnu89 inline，必须用 gnu89 编译，否则链接缺符号
RUN ln -sf /usr/include/mariadb /usr/include/mysql \
 && (cd saac && make clean >/dev/null 2>&1 || true) \
 && (cd gmsv && make clean >/dev/null 2>&1 || true) \
 && cd saac \
 && make -j"$(nproc)" CFLAGS="-O2 -std=gnu89 -w -I. -I./include" MYSQL="-lz -lmariadb" \
 && strip saacjt.exe \
 && cd ../gmsv \
 && make -j"$(nproc)" CFLAGS="-O2 -std=gnu89 -w -I. -I./include -I../include" \
 && strip gmsvjt.exe

RUN mkdir -p /app/saac/char /app/saac/log /app/saac/lock /app/gmsv/log \
 && chmod +x /app/saac/saacjt.exe /app/gmsv/gmsvjt.exe

COPY docker/entrypoint-saac.sh /usr/local/bin/entrypoint-saac
COPY docker/entrypoint-gmsv.sh /usr/local/bin/entrypoint-gmsv
RUN chmod +x /usr/local/bin/entrypoint-saac /usr/local/bin/entrypoint-gmsv

WORKDIR /app/saac
ENTRYPOINT ["/usr/local/bin/entrypoint-saac"]
