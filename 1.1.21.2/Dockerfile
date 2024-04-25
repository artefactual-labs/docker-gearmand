FROM alpine:3.19.1

ENV GEARMAND_VERSION 1.1.21
ENV GEARMAND_SHA1 472d2a0019e69edefcd0c1ff57e9352982e6d3f5

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

RUN addgroup -S gearman && adduser -G gearman -S -D -H -s /bin/false -g "Gearman Server" gearman

RUN apk add --no-cache --virtual .build-deps \
		wget \
		tar \
		ca-certificates \
		file \
		alpine-sdk \
		gperf \
		libuuid \
		boost-dev \
		libevent-dev \
		util-linux-dev \
		hiredis-dev \
		mariadb-dev \
		libmemcached-dev \
	&& wget -O gearmand.tar.gz "https://github.com/gearman/gearmand/releases/download/$GEARMAND_VERSION/gearmand-$GEARMAND_VERSION.tar.gz" \
	&& echo "$GEARMAND_SHA1  gearmand.tar.gz" | sha1sum -c - \
	&& mkdir -p /usr/src/gearmand \
	&& tar -xzf gearmand.tar.gz -C /usr/src/gearmand --strip-components=1 \
	&& rm gearmand.tar.gz \
	&& cd /usr/src/gearmand \
	&& ./configure \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--with-mysql=yes \
		--with-postgresql=no \
		--disable-libpq \
		--disable-libtokyocabinet \
		--disable-libdrizzle \
		--enable-ssl \
		--enable-hiredis \
		--enable-jobserver=no \
	&& make \
	&& make install \
	&& cd / && rm -rf /usr/src/gearmand \
	&& runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed || true \
			| sort -u \
	)" \
	&& apk add --virtual .gearmand-rundeps $runDeps \
	&& apk del .build-deps \
	&& /usr/local/sbin/gearmand --version

HEALTHCHECK --interval=5m --timeout=3s --retries=2 \
	CMD test $(netstat -ltn | grep -c :$GEARMAND_LISTEN_PORT) -eq 1 || exit 1

COPY docker-entrypoint.sh /usr/local/bin/
RUN apk add --no-cache bash \
    && touch /etc/gearmand.conf && chown gearman:gearman /etc/gearmand.conf \
    && ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

USER gearman
EXPOSE $GEARMAND_LISTEN_PORT
CMD ["gearmand"]
