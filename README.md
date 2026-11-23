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

## Documentation

All JFrog links are from [docs.jfrog.com](https://docs.jfrog.com).

### Shared: authentication, repositories and CLI

| Topic | Link |
|---|---|
| Authenticate GitHub Actions with OIDC (used by every workflow) | [GitHub Actions OIDC authentication](https://docs.jfrog.com/integrations/docs/github-actions-oidc-authentication) |
| OpenID Connect integrations and identity mappings | [OpenID Connect Authentication](https://docs.jfrog.com/security/docs/openid-connect-authentication) |
| Set up JFrog CLI in GitHub Actions (`jfrog/setup-jfrog-cli`) | [GitHub Actions](https://docs.jfrog.com/integrations/docs/github-actions) |
| JFrog CLI install and command reference | [Quick start](https://docs.jfrog.com/integrations/docs/jfrog-cli-quick-start), [Command reference](https://docs.jfrog.com/integrations/docs/jfrog-cli-command-reference) |
| Job summaries written by the CLI | [Publish a JFrog CLI Job Summary](https://docs.jfrog.com/integrations/docs/github-actions-job-summary) |
| Local, remote and virtual repositories (`00-bootstrap`) | [Repository Management](https://docs.jfrog.com/artifactory/docs/repository-management), [Virtual Repositories](https://docs.jfrog.com/artifactory/docs/virtual-repositories) |
| Docker and OCI repositories | [Docker Repositories](https://docs.jfrog.com/artifactory/docs/docker-repositories), [OCI Repositories](https://docs.jfrog.com/artifactory/docs/oci-repositories) |

### 01 OCI labels as properties

| Topic | Link |
|---|---|
| Labels extracted into `manifest.json` properties | [Additional Docker Information, Docker Labels](https://docs.jfrog.com/artifactory/docs/additional-docker-information) |
| Properties in Artifactory | [JFrog Properties](https://docs.jfrog.com/artifactory/docs/jfrog-properties) |
| Searching with AQL (`queries/labels.aql`) | [Artifactory Query Language](https://docs.jfrog.com/artifactory/docs/artifactory-query-language), [Search Criteria and Operators](https://docs.jfrog.com/artifactory/docs/aql-search-criteria), [AQL Examples](https://docs.jfrog.com/artifactory/docs/aql-examples), [Query Execution and Permissions](https://docs.jfrog.com/artifactory/docs/aql-query-execution) |

### 02 `build-docker-create` and Evidence

| Topic | Link |
|---|---|
| What Build-Info is | [About Build Info](https://docs.jfrog.com/integrations/docs/about-build-info), [Build Integration](https://docs.jfrog.com/integrations/docs/build-integration) |
| `jf rt build-docker-create` for images pushed outside the CLI | [Advanced Docker Operations with JFrog CLI](https://docs.jfrog.com/artifactory/docs/docker-advanced-operations) |
| Where Build-Info is stored | [Build-Info Repository](https://docs.jfrog.com/integrations/docs/build-info-repository) |
| GitHub build attestation becomes Evidence | [Create JFrog Evidence from a GitHub Attestation](https://docs.jfrog.com/integrations/docs/github-actions-github-attestation-to-jfrog-evidence) |
| Evidence concepts, viewing and searching | [Evidence Management](https://docs.jfrog.com/governance/docs/evidence-management), [View Evidence](https://docs.jfrog.com/governance/docs/view-evidence), [Search for Evidence Using GraphQL](https://docs.jfrog.com/governance/docs/search-for-evidence-using-graphql) |
| Signed custom Evidence with the CLI (optional extension) | [Creating Evidence Using the JFrog CLI](https://docs.jfrog.com/governance/docs/create-evidence-using-the-jfrog-cli) |
| Upstream GitHub action used for attestations | [actions/attest-build-provenance](https://github.com/actions/attest-build-provenance) |

### 03 Xray Base Image Detection

| Topic | Link |
|---|---|
| The feature, prerequisites and the Exclude Base Image filter | [Base Image Detection](https://docs.jfrog.com/security/docs/base-image-detection) |
| SBOM service (required; self-managed migration) | [Enable and Monitor SBOM Migration](https://docs.jfrog.com/security/docs/how-to-enable-and-monitor-sbom-migration-in-xray) |
| Docker / OCI scanning support | [Docker / OCI in Xray](https://docs.jfrog.com/security/docs/xray-docker-containers) |
| Indexing repositories and builds, retention | [Index Xray Resources](https://docs.jfrog.com/security/docs/index-xray-resources), [Configure Indexing](https://docs.jfrog.com/security/docs/configure-indexing-in-jfrog-xray), [Set a Retention Period](https://docs.jfrog.com/security/docs/set-a-retention-period-for-xray-indexed-resources) |
| Policies (including the *Skip base image* option) and watches | [Policies in Xray](https://docs.jfrog.com/security/docs/policies-in-jfrog-xray), [Create Policies](https://docs.jfrog.com/security/docs/create-policies), [Watches in Xray](https://docs.jfrog.com/security/docs/watches-in-jfrog-xray), [Create Watches](https://docs.jfrog.com/security/docs/create-watches) |
