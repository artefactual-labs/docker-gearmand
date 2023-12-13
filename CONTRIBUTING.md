# Contributing

## Release

### Tag policy

Tags are immutable, if `1.1.21.1-alpine` needs an update we will publish `1.1.21.2-alpine` instead.

### Manual builds

The publishing process is done manually for now, e.g.:

    docker buildx build -t artefactual/gearmand:1.1.21.1-alpine -t artefactual/gearmand:latest --platform linux/arm64,linux/amd64 --push .

We rely on BuildKit's automatic QEMU emulation support.

## Discuss possible improvements

- Transfer ownership to Gearman maintainers
- Automated builds
- Vulnerability scanning
- Supply chain attestations
- Use of Melange, Apko and Wolfi
- Integration with https://github.com/gearman/gearmand
