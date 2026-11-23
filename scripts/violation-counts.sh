#!/usr/bin/env bash
# Usage: violation-counts.sh <watch> <image>  -> prints the count of violations on <image>
source "$(dirname "$0")/lib.sh"
jq -nc --arg w "$1" '{filters:{watch_name:$w, include_details:true}, pagination:{limit:1000, offset:1}}' \
  | xr -s -XPOST /api/v1/violations -H 'Content-Type: application/json' -d @- \
  | jq --arg img "$2" '[.violations[]? | select(any(.impacted_artifacts[]?; contains("/" + $img + "/")))] | length'
