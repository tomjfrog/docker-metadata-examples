#!/usr/bin/env bash
# Idempotent bootstrap: local + virtual Docker repos, Xray repo indexing, build indexing.
source "$(dirname "$0")/lib.sh"

ensure_repo() { # $1=key $2=json
  local code; code=$(rt_status "/api/repositories/$1")
  if [[ "$code" == "200" ]]; then echo "exists: $1"; return; fi
  echo "creating: $1"
  printf '%s' "$2" | rt -s -f -XPUT "/api/repositories/$1" -H 'Content-Type: application/json' -d @- >/dev/null
}

# The shared Docker Hub remote must already exist.
[[ "$(rt_status "/api/repositories/${REPO_REMOTE}")" == "200" ]] \
  || { echo "::error::Remote repo ${REPO_REMOTE} not found. Set REPO_REMOTE to a Docker remote."; exit 1; }

ensure_repo "$REPO_LOCAL" "$(jq -nc --arg k "$REPO_LOCAL" '{key:$k,rclass:"local",packageType:"docker",
  dockerApiVersion:"V2",xrayIndex:true,description:"OCI metadata demo: local Docker repo"}')"

ensure_repo "$REPO_VIRTUAL" "$(jq -nc --arg k "$REPO_VIRTUAL" --arg l "$REPO_LOCAL" --arg r "$REPO_REMOTE" \
  '{key:$k,rclass:"virtual",packageType:"docker",repositories:[$l,$r],defaultDeploymentRepo:$l,
    description:"OCI metadata demo: virtual Docker repo (local + Docker Hub remote)"}')"

# Xray: index the local repo (read-modify-write so existing settings survive)
CUR=$(xr -s "/api/v1/repos_config/${REPO_LOCAL}" || true)
if ! echo "$CUR" | jq -e '.repo_config' >/dev/null 2>&1; then
  CUR=$(jq -nc --arg r "$REPO_LOCAL" '{repo_name:$r,repo_config:{}}')
fi
echo "$CUR" | jq -c '.repo_config.retention_in_days = 90' \
  | xr -s -XPUT /api/v1/repos_config -H 'Content-Type: application/json' -d @- \
  || echo "::warning::Could not set Xray repos_config (check Xray entitlement)"

# Xray: index the demo build
CUR=$(xr -s "/api/v1/binMgr/default/builds" || echo '{}')
echo "$CUR" | jq -c --arg b "$BUILD_NAME" '.indexed_builds = ((.indexed_builds // []) + [$b] | unique)' \
  | xr -s -XPUT /api/v1/binMgr/default/builds -H 'Content-Type: application/json' -d @- \
  || echo "::warning::Could not index build ${BUILD_NAME}"

{
  echo "### Bootstrap complete"
  echo "- Local repo: \`${REPO_LOCAL}\` (Xray indexed)"
  echo "- Virtual repo: \`${REPO_VIRTUAL}\` = \`${REPO_LOCAL}\` + \`${REPO_REMOTE}\`"
  echo "- Build \`${BUILD_NAME}\` added to Xray build indexing"
} | summary
