#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 3 ]]; then
	echo "Usage: $0 SBOM_FILE PROJECT_NAME PROJECT_VERSION" >&2
	exit 1
fi

sbom_file=$1
project_name=$2
project_version=$3

: "${DEPENDENCY_TRACK_URL:?Set DEPENDENCY_TRACK_URL}"
: "${DEPENDENCY_TRACK_API_KEY:?Set DEPENDENCY_TRACK_API_KEY}"
: "${project_name:?Project name must not be empty}"
: "${project_version:?Project version must not be empty}"

jq -e '.bomFormat == "CycloneDX" and (.components | length > 0)' \
	"$sbom_file" > /dev/null

response="$(
	curl --fail --silent --show-error \
		--connect-timeout 10 --max-time 120 \
		--header "X-Api-Key: ${DEPENDENCY_TRACK_API_KEY}" \
		--form-string "autoCreate=true" \
		--form-string "projectName=${project_name}" \
		--form-string "projectVersion=${project_version}" \
		--form "bom=@${sbom_file}" \
		"${DEPENDENCY_TRACK_URL%/}/api/v1/bom"
)"

jq -e '.token | strings | select(length > 0)' <<< "$response" > /dev/null
echo "SBOM accepted for ${project_name} ${project_version}; analysis is asynchronous."
