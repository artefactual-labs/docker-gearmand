#!/usr/bin/env bash
set -Eeuo pipefail

version=${1:-2.1.0}
test_id=$$
image="docker-gearmand:image-smoke-${test_id}"
container="docker-gearmand-image-smoke-${test_id}"
listen_port=4731

cleanup() {
	docker rm --force "${container}" >/dev/null 2>&1 || true
	docker image rm "${image}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

if [[ ! -f "${version}/Dockerfile" ]]; then
	echo "Build context not found: ${version}/Dockerfile" >&2
	exit 1
fi

docker build --tag "${image}" "${version}"

reported_version="$(docker run --rm "${image}" gearmand --version)"
if [[ "${reported_version}" != *"gearmand ${version}"* ]]; then
	echo "Expected gearmand ${version}, got: ${reported_version}" >&2
	exit 1
fi

default_retries="$(
	docker run --rm "${image}" \
		bash -c 'grep -F -- "--job-retries=" /etc/gearmand.conf'
)"
if [[ "${default_retries}" != "--job-retries=-1" ]]; then
	echo "Expected unlimited retries by default, got: ${default_retries}" >&2
	exit 1
fi

zero_retries="$(
	docker run --rm \
		--env JOB_RETRIES=0 \
		"${image}" \
		bash -c 'grep -F -- "--job-retries=" /etc/gearmand.conf'
)"
if [[ "${zero_retries}" != "--job-retries=0" ]]; then
	echo "Expected JOB_RETRIES=0 to be preserved, got: ${zero_retries}" >&2
	exit 1
fi

docker run --detach \
	--name "${container}" \
	--env LISTEN_PORT="${listen_port}" \
	--health-interval=1s \
	--health-timeout=3s \
	--health-retries=10 \
	"${image}" >/dev/null

healthy=false
for _ in {1..30}; do
	running="$(
		docker inspect --format '{{.State.Running}}' "${container}" 2>/dev/null || true
	)"
	if [[ "${running}" != true ]]; then
		echo "gearmand exited before becoming healthy" >&2
		docker logs "${container}" >&2
		exit 1
	fi

	health="$(
		docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' \
			"${container}"
	)"
	if [[ "${health}" == healthy ]]; then
		healthy=true
		break
	fi
	if [[ "${health}" == unhealthy ]]; then
		echo "gearmand health check failed" >&2
		docker inspect --format '{{json .State.Health}}' "${container}" >&2
		docker logs "${container}" >&2
		exit 1
	fi
	sleep 1
done

if [[ "${healthy}" != true ]]; then
	echo "gearmand did not become healthy" >&2
	docker inspect --format '{{json .State.Health}}' "${container}" >&2
	docker logs "${container}" >&2
	exit 1
fi

docker exec "${container}" \
	gearmand --check-args \
	--queue-type=libsqlite3 \
	--libsqlite3-db=/tmp/gearmand.sqlite

echo "Gearmand ${version} image smoke test passed"
