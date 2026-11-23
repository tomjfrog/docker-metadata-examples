#!/usr/bin/env bash
# Usage: show-labels.sh <image> <tag>  -> markdown table of docker.label.* properties
source "$(dirname "$0")/lib.sh"
img=$1; tag=$2
echo "#### \`${img}:${tag}\`"
echo
echo "| Property | Value |"
echo "|---|---|"
rt -s "/api/storage/${REPO_LOCAL}/${img}/${tag}/manifest.json?properties" \
  | jq -r '.properties | to_entries[] | select(.key|startswith("docker.label.")) | "| `\(.key)` | `\(.value|join(","))` |"' | sort
echo
