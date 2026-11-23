#!/usr/bin/env bash
# Usage: classify-by-layer.sh <base-summary.json> <app-summary.json>
# Technique (not a product field): an app finding is base-origin when the layer
# blob in its impact path also appears in the base image's scan.
set -euo pipefail
base=$1; app=$2
layer() { sed -E 's#.*/(sha256__[0-9a-f]{64})\.tar\.gz.*#\1#'; }
jq -r '.artifacts[0].issues[]?.impact_path[]? | select(test("sha256__[0-9a-f]{64}"))' "$base" | layer | sort -u > /tmp/base-layers.txt
jq -r '.artifacts[0].issues[] | .issue_id as $id | .severity as $sev | .impact_path[]? | select(test("sha256__[0-9a-f]{64}")) | [$id,$sev,.] | @tsv' "$app" \
  | while IFS=$'\t' read -r id sev path; do
      l=$(printf '%s' "$path" | layer)
      if grep -qx "$l" /tmp/base-layers.txt; then o=base; else o=app; fi
      printf '%s\t%s\t%s\t%s\n' "$o" "$id" "$sev" "$l"
    done > /tmp/classified.tsv
echo "| Origin | Findings | Layer(s) |"
echo "|---|---|---|"
for o in base app; do
  n=$(awk -F'\t' -v o=$o '$1==o' /tmp/classified.tsv | wc -l | tr -d ' ')
  ls=$(awk -F'\t' -v o=$o '$1==o{print substr($4,9,12)}' /tmp/classified.tsv | sort -u | paste -sd, -)
  echo "| ${o} | ${n} | \`${ls:-none}\` |"
done
