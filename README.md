# gearmand
[![](https://images.microbadger.com/badges/image/artefactual/gearmand.svg)](https://microbadger.com/images/artefactual/gearmand)

`artefactual/gearmand` is a Docker image based in Alpine Linux and the most recent version of gearmand.

## Supported tags and respective `Dockerfile` links

- [`latest` (*Dockerfile*)](https://github.com/artefactual-labs/docker-gearmand/tree/master/Dockerfile)) (v1.1.15)

## Supported gearmand backends

- `builtin` (default)
- `redis`

To be added: `libmemcached` (see related [issue](https://github.com/gearman/gearmand/issues/92#issuecomment-290227031)).

## Usage

Print help:

```bash
docker run --rm -i artefactual-labs/gearmand:latest --help
```

Use `redis` backend:

```bash
docker run --rm -i gearmand:1.1.15-alpine --redis-server 192.168.1.1 --redis-port 6380
```

You can also inject a new version of `/etc/gearmand.conf` as needed. See the [default](https://github.com/artefactual-labs/docker-gearmand/blob/master/gearmand.conf).
