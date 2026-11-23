# Docker / OCI image metadata on JFrog Artifactory

Three GitHub Actions workflows, each demonstrating one way Artifactory extracts, uses and searches OCI image metadata. Every workflow writes its findings to the **job summary**.

| Workflow | Feature | What it proves |
|---|---|---|
| `01-oci-labels-as-properties` | Dockerfile `LABEL`s become `docker.label.*` properties | Labels are searchable (REST, AQL, CLI); child images inherit base labels; overrides win |
| `02-build-docker-create` | `jf rt build-docker-create` + GitHub build attestation | Build-Info for an image pushed with plain Docker; SLSA provenance lands as Evidence |
| `03-xray-base-image-detection` | Xray Base Image Detection | Findings owned by the base image vs the app; `skip_base_image` policy changes violation counts |

`00-bootstrap` creates the repos and Xray indexing; `99-teardown` removes them (type `DELETE`).

## Setup

1. Repository **variables**: `JF_URL` (e.g. `https://<tenant>.jfrog.io`), `JF_DOCKER_REGISTRY` (host only), `OIDC_PROVIDER_NAME` (a JFrog OIDC integration of type GitHub with an identity mapping that matches this repo/owner and grants repo + Xray access).
2. A Docker Hub remote repo named `dockerhub-remote` (override with `REPO_REMOTE` in `scripts/lib.sh`).
3. Xray with the SBOM service (needed for base image detection) and Evidence enabled.
4. Run `00`, then `01`, `02`, `03` in any order.

Auth is OIDC via `jfrog/setup-jfrog-cli@v4`; no long-lived secrets.

## Things to know

- **`build-docker-create` does not read Dockerfiles.** It records an image that is already in Artifactory (by digest) and its layers as Build-Info artifacts.
- **Labels are copied to properties per image.** Docker inherits labels through `FROM`; Artifactory then writes them on each image's own `manifest.json`. It does not walk parent images.
- **Base/app origin is not an API field.** Xray shows it in the UI (**Exclude Base Image**), exports and `skip_base_image` policies. Workflow 3 shows it via a with/without-skip policy comparison, plus a layer-digest comparison (a technique, not a product feature).
- Base image detection needs both images scanned in the same Xray, **base first**, and within retention.
- Single-platform `linux/amd64` builds with `provenance: false` keep one `manifest.json` per tag, so labels, Xray paths and Evidence share one subject. Multi-arch tags use `list.manifest.json`.
- The `skip_base_image` policy field is not in the public API docs; it was confirmed by reading back a UI-created policy.
