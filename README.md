# gearmand
[![](https://images.microbadger.com/badges/image/artefactual/gearmand.svg)](https://microbadger.com/images/artefactual/gearmand)

`artefactual/gearmand` is an attempt to package Docker images of the latest version of gearmand available using Alpine Linux as the base image.

## Supported tags and respective `Dockerfile` links

- [`latest` (*Dockerfile*)](https://github.com/artefactual-labs/docker-gearmand/tree/master/Dockerfile) (v1.1.15)

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

You can also inject a new version of `/etc/gearmand.conf` as needed. See the [default](https://github.com/artefactual-labs/docker-gearmand/blob/master/gearmand.conf).
