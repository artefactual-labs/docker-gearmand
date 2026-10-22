# alpine:3.24.3
ARG ALPINE_IMAGE=alpine@sha256:b3413572228e34bd1c9245f5565e6cd127005655e8a7899aef33d8e83255c9e6

# ---------------------------------------------------------------- [Build Stage]
FROM ${ALPINE_IMAGE} AS build

ENV GEARMAND_VERSION=2.2.0

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

COPY pubkey.asc /pubkey.asc

# Require the CA update that distrusts the compromised eMudhra chains.
# Package list 'runDeps' is programmatically generated.
# hadolint ignore=SC2086, DL3019
RUN apk add --no-cache --virtual .build-deps \
	wget \
	tar \
	'ca-certificates>=20261020-r0' \
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
	openssl-dev \
	sqlite-dev \
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
	--with-sqlite3=yes \
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

FROM ${ALPINE_IMAGE}

ENV GEARMAND_LISTEN_PORT=4730

COPY --from=build /usr/local /usr/local
COPY --from=build /run-deps.txt /run-deps.txt

COPY docker-entrypoint.sh /usr/local/bin/

RUN set -eux; \
	xargs apk add --no-cache bash 'ca-certificates-bundle>=20261020-r0' < /run-deps.txt; \
	addgroup -S gearman; \
	adduser -S -D -H -s /sbin/nologin -G gearman -g "Gearman Server" gearman; \
	install -o gearman -g gearman -m 0644 /dev/null /etc/gearmand.conf; \
	ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh

HEALTHCHECK --interval=5m --timeout=3s --retries=2 \
	CMD ["sh", "-c", "exec gearman --ping -h 127.0.0.1 -p \"${GEARMAND_PORT:-${LISTEN_PORT:-$GEARMAND_LISTEN_PORT}}\" -t 2000"]

USER gearman
EXPOSE ${GEARMAND_LISTEN_PORT}
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["gearmand"]
