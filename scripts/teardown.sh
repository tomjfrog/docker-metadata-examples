#!/usr/bin/env bash
# Deletes ONLY the named demo resources. Order: watches, policies, build, repos.
source "$(dirname "$0")/lib.sh"
for w in bid-watch-all bid-watch-app-only; do xr -s -XDELETE "/api/v2/watches/$w" || true; echo; done
for p in bid-all-vulns bid-app-only; do xr -s -XDELETE "/api/v2/policies/$p" || true; echo; done
rt -s -XDELETE "/api/build/${BUILD_NAME}?deleteAll=1" || true; echo
rt -s -XDELETE "/api/repositories/${REPO_VIRTUAL}" || true; echo
rt -s -XDELETE "/api/repositories/${REPO_LOCAL}" || true; echo
echo "teardown requested for: ${REPO_VIRTUAL}, ${REPO_LOCAL}, build ${BUILD_NAME}, bid-* watches/policies"
