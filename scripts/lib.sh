#!/usr/bin/env bash
# Shared helpers. In GitHub Actions, setup-jfrog-cli configures the default server.
# Locally, set JF_SERVER_ID=<server-id> to target a specific `jf config` entry.
set -euo pipefail

: "${REPO_LOCAL:=oci-metadata-docker-local}"
: "${REPO_VIRTUAL:=oci-metadata-docker}"
: "${REPO_REMOTE:=dockerhub-remote}"
: "${BUILD_NAME:=oci-metadata-build-info}"

# Artifactory REST (path relative to /artifactory)
rt()  { jf rt curl ${JF_SERVER_ID:+--server-id "$JF_SERVER_ID"} "$@"; }
# Xray REST (path relative to /xray)
xr()  { jf xr curl ${JF_SERVER_ID:+--server-id "$JF_SERVER_ID"} "$@"; }
# HTTP status code of an Artifactory GET
rt_status() { rt -s -o /dev/null -w '%{http_code}' "$1"; }

summary() { # append markdown to the job summary (or stdout when local)
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then cat >> "$GITHUB_STEP_SUMMARY"; else cat; fi
}
