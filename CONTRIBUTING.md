# Contributing

## Workflow checks

Run [jactionlint] before committing workflow changes:

```bash
jactionlint --strict-exit
gh actions-lock --verify
```

Install the lockfile tool with
`gh extension install github/gh-actions-lock --pin v0.2.0`. After adding or
updating an action, run `gh actions-lock` and commit the generated
`.github/workflows/actions.lock` alongside the workflow changes.

The configuration uses the pedantic profile. The `unpinned-uses` rule is
disabled because `gh actions-lock --verify` checks the lockfile pins. Docker Hub
credentials remain repository secrets, so the environment-secret rule is
disabled.

Dependabot checks GitHub Actions weekly, with a seven-day cooldown and one
grouped version-update pull request at a time. It also checks Alpine daily in
the current release tree without a cooldown, with one Docker update pull request
at a time. The explicit version tag and digest in the shared `base` stage let
Dependabot update both while keeping the image pinned.

Treat Docker update pull requests for a published tree as proposals for the next
packaging revision: copy the released tree, apply the proposed update there, and
leave the published tree unchanged. Update the Dependabot directory, CI version,
test defaults, and README when preparing that revision. Do not auto-merge Docker
updates into a published tree. These are version updates; Dependabot does not
scan installed Alpine packages for vulnerabilities.

The `gh-actions-lock` extension version in the installation command must still
be updated manually.

## How to release

Each upstream Gearman release has its own dedicated tree at the repository root
(for example, [2.2.0]). The first image release uses the upstream version
unchanged.

Release trees are immutable. Beginning with Gearman 2.0.0, if an image must be
rebuilt without changing the Gearman version (e.g., to include a newer Alpine or
another packaging change), create a new tree with the next packaging revision,
such as `2.2.0-r1` and then `2.2.0-r2`. Keep `GEARMAND_VERSION` set to the
upstream version (`2.2.0` in these examples).

Use the latest stable Alpine release when preparing an image release, with both
its version tag and multi-platform digest pinned in the `base` stage (for
example, `alpine:3.24.4@sha256:...`).

Gearman 1.x image releases retain the legacy dotted packaging revision scheme,
such as `1.1.22.1`. Existing 1.x releases will not be renamed to use `-rN`.

1. Prepare release, e.g. see the [2.2.0-r1] directory.

2. Update `CURRENT_VERSION` in `checks.yml` to the new release tree.

3. Launch the release workflow:

   ```bash
   gh workflow run release.yml --field version=2.2.0-r1
   ```

The release workflow accepts 1.x versions using `1.Y.Z` or `1.Y.Z.N`, and
versions from 2.0.0 onwards using `X.Y.Z` or `X.Y.Z-rN` (where `N` starts at 1).
The input must match a release tree in the repository.

## Future improvements

> [!NOTE]
> Long-term goal: transfer ownership to Gearman maintainers.

- [x] Automate release process
- [x] Publish multi-arch images
- [x] Pin actions in GitHub workflows
- [ ] Reduce duplication across release trees (template or generator)
- [ ] Check current release(s) dynamically in `checks.yml`
- [x] Publish runtime SBOMs and upload them to Dependency-Track
- [ ] Publish provenance output and sign images
- [x] Run image validation tests
- [ ] Convert entrypoint to POSIX `sh` (drop `bash`)
- [x] Configure GitHub Actions dependency updates
- [ ] Improve build reproducibility (deterministic builds, pinned deps)
- [x] Enforce a release vulnerability policy
- [ ] Supply chain attestations (SLSA, provenance, SBOMs)
- [x] Improve healthcheck robustness (avoid `netstat`)

[2.2.0]: https://github.com/artefactual-labs/docker-gearmand/tree/main/2.2.0
[2.2.0-r1]: https://github.com/artefactual-labs/docker-gearmand/tree/main/2.2.0-r1
[jactionlint]: https://github.com/jdx/jactionlint
