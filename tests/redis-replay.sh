#!/usr/bin/env bash
set -Eeuo pipefail

version=${1:-2.1.0}
redis_image=${REDIS_IMAGE:-redis@sha256:ff02b58f971e7d7d156a1267e283fcbbeee91773b6aa36c49dac28ecfe28eadf} # redis:7.4.11-alpine
test_id=$$
gearmand_image="docker-gearmand:redis-replay-${test_id}"
network="docker-gearmand-redis-replay-${test_id}"
redis_container="docker-gearmand-redis-replay-db-${test_id}"
gearmand_container="docker-gearmand-redis-replay-app-${test_id}"
function_name='reverse-with-hyphens'
unique='unique-with-hyphens'
payload='integration-test-payload'
redis_key="_gear_-${function_name}-${unique}"
legacy_function='legacyfunction'
legacy_unique='legacyunique'
legacy_key="_gear_-${legacy_function}-${legacy_unique}"

cleanup() {
	docker rm --force \
		"${gearmand_container}" \
		"${redis_container}" >/dev/null 2>&1 || true
	docker network rm "${network}" >/dev/null 2>&1 || true
	docker image rm "${gearmand_image}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

if [[ ! -f "${version}/Dockerfile" ]]; then
	echo "Build context not found: ${version}/Dockerfile" >&2
	exit 1
fi

wait_for_gearmand() {
	local healthy=false
	local running
	local health

	for _ in {1..30}; do
		running="$(
			docker inspect --format '{{.State.Running}}' \
				"${gearmand_container}" 2>/dev/null || true
		)"
		if [[ "${running}" != true ]]; then
			echo "gearmand exited before becoming healthy" >&2
			docker logs "${gearmand_container}" >&2
			exit 1
		fi

		health="$(
			docker inspect \
				--format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' \
				"${gearmand_container}"
		)"
		if [[ "${health}" == healthy ]]; then
			healthy=true
			break
		fi
		if [[ "${health}" == unhealthy ]]; then
			echo "gearmand health check failed" >&2
			docker inspect --format '{{json .State.Health}}' \
				"${gearmand_container}" >&2
			docker logs "${gearmand_container}" >&2
			exit 1
		fi
		sleep 1
	done

	if [[ "${healthy}" != true ]]; then
		echo "gearmand did not become healthy" >&2
		docker inspect --format '{{json .State.Health}}' \
			"${gearmand_container}" >&2
		docker logs "${gearmand_container}" >&2
		exit 1
	fi
}

start_gearmand() {
	docker run --detach \
		--name "${gearmand_container}" \
		--network "${network}" \
		--env QUEUE_TYPE=redis \
		--health-interval=1s \
		--health-timeout=3s \
		--health-retries=10 \
		"${gearmand_image}" \
		--redis-server="${redis_container}" \
		--redis-port=6379 >/dev/null
	wait_for_gearmand
}

assert_status() {
	local function=$1
	local status
	local expected

	status="$(
		docker exec "${gearmand_container}" \
			gearadmin --host=127.0.0.1 --port=4730 --status
	)"
	expected="${function}"$'\t1\t0\t0'
	if ! grep -Fqx -- "${expected}" <<<"${status}"; then
		echo "Expected queued function ${function}, got:" >&2
		echo "${status}" >&2
		exit 1
	fi
}

docker build --tag "${gearmand_image}" "${version}"
docker network create "${network}" >/dev/null
docker run --detach \
	--name "${redis_container}" \
	--network "${network}" \
	"${redis_image}" >/dev/null

redis_ready=false
for _ in {1..30}; do
	if docker exec "${redis_container}" redis-cli ping 2>/dev/null | grep -qx PONG; then
		redis_ready=true
		break
	fi
	sleep 1
done

if [[ "${redis_ready}" != true ]]; then
	echo "Redis did not become ready" >&2
	docker logs "${redis_container}" >&2
	exit 1
fi

start_gearmand

docker exec "${gearmand_container}" \
	gearman \
	-h 127.0.0.1 \
	-p 4730 \
	-f "${function_name}" \
	-u "${unique}" \
	-b \
	"${payload}" >/dev/null

stored_function="$(
	docker exec "${redis_container}" \
		redis-cli --raw HGET "${redis_key}" function
)"
stored_unique="$(
	docker exec "${redis_container}" \
		redis-cli --raw HGET "${redis_key}" unique
)"
if [[ "${stored_function}" != "${function_name}" ]]; then
	echo "Expected Redis function field ${function_name}, got: ${stored_function}" >&2
	exit 1
fi
if [[ "${stored_unique}" != "${unique}" ]]; then
	echo "Expected Redis unique field ${unique}, got: ${stored_unique}" >&2
	exit 1
fi

docker exec "${redis_container}" \
	redis-cli HSET "${legacy_key}" data legacy-payload priority 1 >/dev/null

docker rm --force "${gearmand_container}" >/dev/null
start_gearmand

assert_status "${function_name}"
assert_status "${legacy_function}"

echo "Redis queue replay succeeded for current and legacy records"
