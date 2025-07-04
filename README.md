# gearmand
[![Latest Release](https://img.shields.io/docker/v/artefactual/gearmand?style=flat-square)](https://github.com/artefactual-labs/docker-gearmand)

`artefactual/gearmand` packages recent versions of gearmand using Alpine Linux as the base image.

## Supported tags and respective `Dockerfile` links

Only the following version is currently supported and maintained:

- [`1.1.21.5-alpine`, `1.1.21.5`, `latest` (*Dockerfile*)](1.1.21.5/Dockerfile)

This image is built on version [1.1.21] of [gearmand].

[1.1.21]: https://github.com/gearman/gearmand/releases/tag/1.1.21
[gearmand]: https://github.com/gearman/gearmand

> [!WARNING]
> Older releases are no longer maintained and may contain unpatched security vulnerabilities and outdated dependencies. While these images remain available in the container registry, we strongly discourage their use.

## Supported gearmand backends

- `builtin` (default)
- `libmemcached`
- `mysql` (using `mariadb-dev`)
- `redis`

## Usage

Print help:

```bash
docker run --rm -i artefactual/gearmand:latest --help
```

Use `redis` backend and set verbose level to `DEBUG`.

```bash
docker run --rm -i artefactual/gearmand:latest --queue-type=redis --redis-server=192.168.1.1 --redis-port=6379 --verbose=DEBUG
```

## Environment variables

This image includes an entry point that translates environment strings into [configuration attributes](http://gearman.info/gearmand.html). The following is a list of the strings currently supported:

| Name                | Description                                                                                                                              | Default                         |
|---------------------|------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------|
| VERBOSE             | Logging level                                                                                                                            | INFO                            |
| GEARMAND_PORT       | Listen port                                                                                                                              | 4730                            |
| QUEUE_TYPE          | Persistent queue type to use                                                                                                             | builtin                         |
| THREADS             | Number of I/O threads to use                                                                                                             | 4                               |
| BACKLOG             | Number of backlog connections for listen                                                                                                 | 32                              |
| FILE_DESCRIPTORS    | Number of file descriptors to allow for the process                                                                                      | Default is max allowed for user |
| JOB_RETRIES         | Number of attempts to run the job before the job server removes it. Default is no limit.                                                 | 0                               |
| ROUND_ROBIN         | Assign work in round-robin order per worker connection                                                                                   | 0                               |
| WORKER_WAKEUP       | Number of workers to wakeup for each job received                                                                                        | 0                               |
| KEEPALIVE           | Enable keepalive on sockets                                                                                                              | 0                               |
| KEEPALIVE_IDLE      | The duration between two keepalive transmissions in idle condition                                                                       | 30                              |
| KEEPALIVE_INTERVAL  | The duration between two successive keepalive retransmissions, if acknowledgement to the previous keepalive transmission is not received | 10                              |
| KEEPALIVE_COUNT     | The number of retransmissions to be carried out before declaring that remote end is not available                                        | 5                               |
| MYSQL_HOST          | MySQL server host                                                                                                                        | localhost                       |
| MYSQL_PORT          | MySQL server port                                                                                                                        | 3306                            |
| MYSQL_USER          | MySQL server user                                                                                                                        | root                            |
| MYSQL_PASSWORD      | MySQL password                                                                                                                           |                                 |
| MYSQL_PASSWORD_FILE | Path to file with MySQL password (Docker secrets)                                                                                        |                                 |
| MYSQL_DB            | Database to use by Gearman                                                                                                               | Gearmand                        |
| MYSQL_TABLE         | Table to use by Gearman                                                                                                                  | gearman_queue                   |

You can also inject your version of config file to `/etc/gearmand.conf` as needed.

## Release process

To create a new release, run the following command, replacing `VERSION` with the
desired version (which must match a directory for the build context in this
repository), e.g. `1.1.21.4`:

    gh workflow run release.yml --field version=VERSION

This command will automatically build and publish the images, create a git tag,
and publish a GitHub release.

## Credits

See the [list of contributors](https://github.com/artefactual-labs/docker-gearmand/graphs/contributors).

Thanks to @Mararok for the new entry point bringing support for environment variables and secrets.
