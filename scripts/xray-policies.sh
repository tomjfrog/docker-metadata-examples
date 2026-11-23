#!/usr/bin/env bash
# Idempotently create two policies/watches that differ ONLY in skip_base_image.
#   A: bid-all-vulns -> bid-watch-all       (no skip)
#   B: bid-app-only  -> bid-watch-app-only  (skip_base_image: true)
source "$(dirname "$0")/lib.sh"

mk_policy() { # $1=name $2=skip(true|false)
  if [[ "$(xr -s -o /dev/null -w '%{http_code}' "/api/v2/policies/$1")" == 200 ]]; then echo "policy exists: $1"; return; fi
  jq -nc --arg n "$1" --argjson skip "$2" '{
    name:$n, type:"security", description:"OCI metadata demo (base image detection)",
    rules:[{name:"medium-and-above", priority:1,
      criteria:({min_severity:"medium"} + (if $skip then {skip_base_image:true} else {} end)),
      actions:{block_download:{active:false,unscanned:false}, fail_build:false, notify_watch_recipients:false}}]}' \
  | xr_json POST /api/v2/policies >/dev/null
  echo "policy created: $1"
}
mk_watch() { # $1=watch $2=policy
  if [[ "$(xr -s -o /dev/null -w '%{http_code}' "/api/v2/watches/$1")" == 200 ]]; then echo "watch exists: $1"; return; fi
  jq -nc --arg w "$1" --arg p "$2" --arg r "$REPO_LOCAL" '{
    general_data:{name:$w, description:"OCI metadata demo", active:true},
    project_resources:{resources:[{type:"repository", bin_mgr_id:"default", name:$r,
                                   filters:[{type:"regex", value:".*"}]}]},
    assigned_policies:[{name:$p, type:"security"}]}' \
  | xr_json POST /api/v2/watches >/dev/null
  echo "watch created: $1"
}
mk_policy bid-all-vulns false
mk_policy bid-app-only  true
mk_watch  bid-watch-all      bid-all-vulns
mk_watch  bid-watch-app-only bid-app-only
