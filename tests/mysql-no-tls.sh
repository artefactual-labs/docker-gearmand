#!/usr/bin/env bash
set -Eeuo pipefail

version=${1:-2.1.0}
mariadb_image=${MARIADB_IMAGE:-mariadb@sha256:be981e4113326ada8d6004174dd09eeaefc03094037f811182a52d4f2e737350} # mariadb:10.11
test_id=$$
gearmand_image="docker-gearmand:mysql-no-tls-${test_id}"
network="docker-gearmand-mysql-no-tls-${test_id}"
database_container="docker-gearmand-mysql-no-tls-db-${test_id}"
gearmand_container="docker-gearmand-mysql-no-tls-app-${test_id}"
database_password=integration-test

cleanup() {
	docker rm --force \
		"${gearmand_container}" \
		"${database_container}" >/dev/null 2>&1 || true
	docker network rm "${network}" >/dev/null 2>&1 || true
	docker image rm "${gearmand_image}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

if [[ ! -f "${version}/Dockerfile" ]]; then
	echo "Build context not found: ${version}/Dockerfile" >&2
	exit 1
fi

docker build --tag "${gearmand_image}" "${version}"
docker network create "${network}" >/dev/null
docker run --detach \
	--name "${database_container}" \
	--network "${network}" \
	--env MARIADB_ROOT_PASSWORD="${database_password}" \
	--env MARIADB_DATABASE=Gearmand \
	"${mariadb_image}" \
	--skip-ssl >/dev/null

database_ready=false
for _ in {1..60}; do
	if docker exec \
		--env MYSQL_PWD="${database_password}" \
		"${database_container}" \
		mariadb-admin ping \
		--host=127.0.0.1 \
		--user=root \
		--silent >/dev/null 2>&1; then
		database_ready=true
		break
	fi
	sleep 1
done

if [[ "${database_ready}" != true ]]; then
	echo "MariaDB did not become ready" >&2
	docker logs "${database_container}" >&2
	exit 1
fi

have_ssl="$(
	docker exec \
		--env MYSQL_PWD="${database_password}" \
		"${database_container}" \
		mariadb \
		--batch \
		--skip-column-names \
		--user=root \
		--execute="SHOW VARIABLES LIKE 'have_ssl';"
)"
if [[ "${have_ssl}" != *$'\tDISABLED' ]]; then
	echo "Expected MariaDB TLS support to be disabled, got: ${have_ssl}" >&2
	exit 1
fi

docker run --detach \
	--name "${gearmand_container}" \
	--network "${network}" \
	--env QUEUE_TYPE=mysql \
	--env MYSQL_HOST="${database_container}" \
	--env MYSQL_USER=root \
	--env MYSQL_PASSWORD="${database_password}" \
	--env MYSQL_DB=Gearmand \
	--env MARIADB_TLS_DISABLE_PEER_VERIFICATION=1 \
	"${gearmand_image}" >/dev/null

gearmand_ready=false
for _ in {1..30}; do
	if ! docker inspect \
		--format '{{.State.Running}}' \
		"${gearmand_container}" 2>/dev/null | grep -qx true; then
		echo "gearmand exited before becoming ready" >&2
		docker logs "${gearmand_container}" >&2
		exit 1
	fi
	if docker logs "${gearmand_container}" 2>&1 | grep -q "Listening on"; then
		gearmand_ready=true
		break
	fi
	sleep 1
done

if [[ "${gearmand_ready}" != true ]]; then
	echo "gearmand did not become ready" >&2
	docker logs "${gearmand_container}" >&2
	exit 1
fi

table_count="$(
	docker exec \
		--env MYSQL_PWD="${database_password}" \
		"${database_container}" \
		mariadb \
		--batch \
		--skip-column-names \
		--user=root \
		--database=Gearmand \
		--execute="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'Gearmand' AND table_name = 'gearman_queue';"
)"
if [[ "${table_count}" != 1 ]]; then
	echo "Expected gearmand to create the gearman_queue table" >&2
	docker logs "${gearmand_container}" >&2
	exit 1
fi

echo "MySQL queue connected successfully with database TLS disabled"
