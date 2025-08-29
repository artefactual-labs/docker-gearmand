ARG ALPINE_VERSION=3.22.1

# ---------------------------------------------------------------- [Build Stage]
FROM alpine:${ALPINE_VERSION} AS build

ENV GEARMAND_VERSION=1.1.22

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

COPY pubkey.asc /pubkey.asc

# Package list 'runDeps' is programmatically generated.
# hadolint ignore=SC2086, DL3019
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
	gnupg \
	&& wget -O gearmand.tar.gz -q "https://github.com/gearman/gearmand/releases/download/$GEARMAND_VERSION/gearmand-$GEARMAND_VERSION.tar.gz" \
	&& wget -O gearmand.tar.gz.asc -q "https://github.com/gearman/gearmand/releases/download/$GEARMAND_VERSION/gearmand-$GEARMAND_VERSION.tar.gz.asc" \
	&& gpg --import /pubkey.asc \
	&& gpg --verify gearmand.tar.gz.asc gearmand.tar.gz \
	&& mkdir -p /usr/src/gearmand \
	&& tar -xzf gearmand.tar.gz -C /usr/src/gearmand --strip-components=1 \
	&& rm gearmand.tar.gz gearmand.tar.gz.asc \
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
	&& cd / \
	&& rm -rf /usr/src/gearmand \
	&& runDeps="$( \
	scanelf --needed --nobanner --recursive /usr/local \
	| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
	| sort -u \
	| xargs -r apk info --installed || true \
	| sort -u \
	)" \
	&& echo "${runDeps}" > /run-deps.txt

# -------------------------------------------------------------- [Runtime Stage]

FROM alpine:${ALPINE_VERSION}

ENV GEARMAND_LISTEN_PORT=4730

COPY --from=build /usr/local /usr/local
COPY --from=build /run-deps.txt /run-deps.txt

COPY docker-entrypoint.sh /usr/local/bin/

RUN apk add --no-cache bash $(cat /run-deps.txt) \
	&& addgroup -S gearman \
	&& adduser -G gearman -S -D -H -s /bin/false -g 'Gearman Server' gearman \
	&& touch /etc/gearmand.conf && chown gearman:gearman /etc/gearmand.conf \
	&& ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh

HEALTHCHECK --interval=5m --timeout=3s --retries=2 \
	CMD test $(netstat -ltn | grep -c :$GEARMAND_LISTEN_PORT) -eq 1 || exit 1

USER gearman
EXPOSE ${GEARMAND_LISTEN_PORT}
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["gearmand"]
