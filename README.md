# gearmand
[![](https://images.microbadger.com/badges/image/artefactual/gearmand.svg)](https://microbadger.com/images/artefactual/gearmand)

`artefactual/gearmand` packages recent versions of gearmand using Alpine Linux as the base image.

## Supported tags and respective `Dockerfile` links

- [`1.1.15-alpine` (*Dockerfile*)](https://github.com/artefactual-labs/docker-gearmand/tree/master/1.1.15/Dockerfile)
- [`1.1.16-alpine`, `latest` (*Dockerfile*)](https://github.com/artefactual-labs/docker-gearmand/tree/master/1.1.16/Dockerfile)

## Supported gearmand backends

- `builtin` (default)
- `redis`

To be added: `libmemcached` (see related [issue](https://bugs.alpinelinux.org/issues/7065)).

## Usage

Print help:

```bash
docker run --rm -i artefactual/gearmand:latest --help
```

Use `redis` backend and set verbose level to `DEBUG`.

```bash
docker run --rm -i artefactual/gearmand:latest --queue-type=redis --redis-server=192.168.1.1 --redis-port=6379 --verbose=DEBUG
```

You can also inject a new version of `/etc/gearmand.conf` as needed. See the [default](https://github.com/artefactual-labs/docker-gearmand/blob/master/1.1.16/gearmand.conf).
