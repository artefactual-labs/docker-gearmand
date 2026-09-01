# Contributing

## How to release

Each upstream Gearman release has its own dedicated tree at the repository root
(for example, [2.1.0]). The first image release uses the upstream version
unchanged.

Release trees are immutable. Beginning with Gearman 2.0.0, if an image must be
rebuilt without changing the Gearman version (e.g., to include a newer Alpine
or another packaging change), create a new tree with the next packaging
revision, such as `2.1.0-r1` and then `2.1.0-r2`. Keep `GEARMAND_VERSION` set
to the upstream version (`2.1.0` in these examples).

Gearman 1.x image releases retain the legacy dotted packaging revision scheme,
such as `1.1.22.1`. Existing 1.x releases will not be renamed to use `-rN`.

1. Prepare release, e.g. see the [2.1.0] directory.
2. Update `CURRENT_VERSION` in `checks.yml` to the new release tree.
3. Launch the release workflow:

    gh workflow run release.yml --field version=2.1.0

The release workflow accepts 1.x versions using `1.Y.Z` or `1.Y.Z.N`, and
versions from 2.0.0 onwards using `X.Y.Z` or `X.Y.Z-rN` (where `N` starts at
1). The input must match a release tree in the repository.

## Future improvements

> [!NOTE]
> Long-term goal: transfer ownership to Gearman maintainers.

- [x] Automate release process
- [x] Publish multi-arch images
- [x] Pin actions in GitHub workflows
- [ ] Reduce duplication across release trees (template or generator)
- [ ] Check current release(s) dynamically in `checks.yml`
- [ ] Publish SBOM/provenance output and sign images
- [ ] Run image validation tests
- [ ] Convert entrypoint to POSIX `sh` (drop `bash`)
- [ ] Configure dependency/update automation
- [ ] Improve build reproducibility (deterministic builds, pinned deps)
- [ ] Vulnerability scanning
- [ ] Supply chain attestations (SLSA, provenance, SBOMs)
- [x] Improve healthcheck robustness (avoid `netstat`)

[2.1.0]: https://github.com/artefactual-labs/docker-gearmand/tree/main/2.1.0
