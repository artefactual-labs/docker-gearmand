#!/bin/bash
set -eo pipefail
CONFIG_FILE='/etc/gearmand.conf'

VERBOSE=${VERBOSE:-INFO}
QUEUE_TYPE=${QUEUE_TYPE:-builtin}

if [[ -n "$LISTEN_PORT" ]]; then
    export GEARMAND_PORT="$LISTEN_PORT"
fi
if [[ "$GEARMAND_PORT" =~ [^0-9] ]] ; then
    echo "WARNING: Ignoring invalid (non-numeric) value for GEARMAND_PORT: $GEARMAND_PORT"
    unset GEARMAND_PORT
fi

THREADS=${THREADS:-4}
BACKLOG=${BACKLOG:-32}
FILE_DESCRIPTORS=${FILE_DESCRIPTORS:-0}

JOB_RETRIES=${JOB_RETRIES:-0}
ROUND_ROBIN=${ROUND_ROBIN:-0}
WORKER_WAKEUP=${WORKER_WAKEUP:-0}

KEEPALIVE=${KEEPALIVE:-0}
KEEPALIVE_IDLE=${KEEPALIVE_IDLE:-30}
KEEPALIVE_INTERVAL=${KEEPALIVE_INTERVAL:-10}
KEEPALIVE_COUNT=${KEEPALIVE_COUNT:-5}

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- gearmand "$@"
fi

function generate_config() {
	cat <<-__CONFIG_CONTENT__ > "${CONFIG_FILE}"
		--listen=0.0.0.0
		--log-file=stderr
		--verbose=${VERBOSE}
		--queue-type=${QUEUE_TYPE}
		--threads=${THREADS}
		--backlog=${BACKLOG}
		--job-retries=${JOB_RETRIES}
		--worker-wakeup=${WORKER_WAKEUP}
	__CONFIG_CONTENT__

	if [[ "${FILE_DESCRIPTORS}" != '0' ]]; then
		cat <<-__CONFIG_CONTENT__ >> "${CONFIG_FILE}"
			--file-descriptors=${FILE_DESCRIPTORS}
		__CONFIG_CONTENT__
	fi

	if [[ "${ROUND_ROBIN}" != '0' ]]; then
		cat <<-__CONFIG_CONTENT__ >> "${CONFIG_FILE}"
			--round-robin
		__CONFIG_CONTENT__
	fi

	if [[ ${KEEPALIVE} != '0' ]]; then
		cat <<-__CONFIG_CONTENT__ >> "${CONFIG_FILE}"
			--keepalive
			--keepalive-idle=${KEEPALIVE_IDLE}
			--keepalive-interval=${KEEPALIVE_INTERVAL}
			--keepalive-count=${KEEPALIVE_COUNT}
		__CONFIG_CONTENT__
	fi

	if [[ "$QUEUE_TYPE" == 'mysql' ]]; then
		file_env 'MYSQL_PASSWORD'
		cat <<-__CONFIG_CONTENT__ >> "${CONFIG_FILE}"
			--mysql-host=${MYSQL_HOST:-localhost}
			--mysql-port=${MYSQL_PORT:-3306}
			--mysql-user=${MYSQL_USER:-root}
			--mysql-password=${MYSQL_PASSWORD}
			--mysql-db=${MYSQL_DB:-Gearmand}
			--mysql-table=${MYSQL_TABLE:-gearman_queue}
		__CONFIG_CONTENT__
	fi
}

if ! [ -s "${CONFIG_FILE}" ]; then # dont genarate config if current config file is not empty
    generate_config
fi
exec "$@"
