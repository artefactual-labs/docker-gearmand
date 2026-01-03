# Contributing

## How to release

Each release has its own dedicated tree at the repository root (for example,
`1.1.22`). Release trees are immutable: if a new build of `1.1.22` is needed
(e.g., to include a newer Alpine or other dependency), create a new patch tree
such as `1.1.22.1` instead of modifying the existing tree.

1. Prepare release, e.g. see the [1.1.22.1] directory.
2. Launch the release workflow:

    gh workflow run release.yml --field version=1.1.22.1

## Future improvements

> [!NOTE]
> Long-term goal: transfer ownership to Gearman maintainers.

- [x] Automate release process
- [x] Publish multi-arch images
- [x] Pin actions in GitHub workflows
- [ ] Reduce duplication across release trees (template or generator)
- [ ] Lint current release(s) dynamically in `lint.yml`
- [ ] Publish SBOM/provenance output and sign images
- [ ] Run image validation tests
- [ ] Convert entrypoint to POSIX `sh` (drop `bash`)
- [ ] Configure dependency/update automation
- [ ] Improve build reproducibility (deterministic builds, pinned deps)
- [ ] Vulnerability scanning
- [ ] Supply chain attestations (SLSA, provenance, SBOMs)
- [ ] Improve healthcheck robustness (avoid `netstat`)

[1.1.22]: https://github.com/artefactual-labs/docker-gearmand/tree/main/1.1.22
[1.1.22.1]: https://github.com/artefactual-labs/docker-gearmand/tree/main/1.1.22.1
