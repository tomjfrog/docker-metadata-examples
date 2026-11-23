#!/usr/bin/env bash
# Usage: wait-for-xray-scan.sh <image> <tag> <outfile>
# Polls the Xray artifact summary until the scan has issues or the image is clean/scanned.
source "$(dirname "$0")/lib.sh"
img=$1; tag=$2; out=$3
for i in $(seq 1 60); do
  for m in manifest.json list.manifest.json; do
    jq -nc --arg p "default/${REPO_LOCAL}/${img}/${tag}/${m}" '{paths:[$p]}' \
      | xr -s -XPOST /api/v2/summary/artifact -H 'Content-Type: application/json' -d @- > "$out" || true
    if jq -e '(.artifacts // []) | length > 0' "$out" >/dev/null 2>&1; then
      # scanned once general info is present and no error marks it in-progress
      if jq -e '.artifacts[0].general.name? and ((.artifacts[0].issues // []) | length > 0)' "$out" >/dev/null 2>&1; then
        echo "scan ready: ${img}:${tag} (${m}) after $((i*10))s"; exit 0
      fi
    fi
  done
  sleep 10
done
echo "::error::Timed out waiting for Xray scan of ${img}:${tag}"; exit 1
