# gearmand
[![Latest Release](https://img.shields.io/docker/v/artefactual/gearmand?style=flat-square)](https://github.com/artefactual-labs/docker-gearmand)

`artefactual/gearmand` packages recent versions of gearmand using Alpine Linux as the base image.

## Supported tags and respective `Dockerfile` links

Only the following version is currently supported and maintained:

- [`2.1.0-alpine`, `2.1.0`, `latest` (*Dockerfile*)](2.1.0/Dockerfile)

This image is built on version [2.1.0] of [gearmand].

[2.1.0]: https://github.com/gearman/gearmand/releases/tag/2.1.0
[2.0.0]: https://github.com/gearman/gearmand/releases/tag/2.0.0
[gearmand]: https://github.com/gearman/gearmand

> [!WARNING]
> Older releases are no longer maintained and may contain unpatched security vulnerabilities and outdated dependencies. While these images remain available in the container registry, we strongly discourage their use.

## Supported gearmand backends

- `builtin` (default)
- `libmemcached`
- `libsqlite3`
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

The image health check uses the `gearman --ping` client command to verify that
the job server responds to the Gearman protocol. It checks the port configured
by `GEARMAND_PORT`, the legacy `LISTEN_PORT`, or port 4730 by default. Override
the health check when using a custom configuration file that binds another
address or port, or when accepting only SSL connections.

## MySQL queue

Set `QUEUE_TYPE=mysql` and provide the database connection settings to use a
MySQL or MariaDB server for the persistent queue:

```bash
docker run --rm \
  -e QUEUE_TYPE=mysql \
  -e MYSQL_HOST=mysql \
  -e MYSQL_USER=gearman \
  -e MYSQL_PASSWORD=secret \
  -e MYSQL_DB=Gearmand \
  artefactual/gearmand:latest
```

MariaDB Connector/C 3.4 and newer enables verified TLS automatically for TCP
connections. If the database server does not support TLS, gearmand exits with
`SSL is required, but the server does not support it`. Set
`MARIADB_TLS_DISABLE_PEER_VERIFICATION=1` to allow the connector to use an
unencrypted connection:

```yaml
services:
  gearmand:
    image: artefactual/gearmand:latest
    environment:
      QUEUE_TYPE: mysql
      MYSQL_HOST: mysql
      MYSQL_USER: gearman
      MYSQL_PASSWORD: secret
      MYSQL_DB: Gearmand
      MARIADB_TLS_DISABLE_PEER_VERIFICATION: "1"
```

> [!WARNING]
> With gearmand's MySQL queue plugin, this setting makes the database
> connection unencrypted. Use it only when TLS cannot be enabled on the
> database server and the connection travels over a trusted private network.

## Environment variables

This image includes an entry point that translates environment strings into [configuration attributes](https://gearman.org/manual/job_server/). The following is a list of the strings currently supported:

| Name                                  | Description                                                                                                                              | Default                         |
|---------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------|
| VERBOSE                               | Logging level                                                                                                                            | INFO                            |
| GEARMAND_PORT                         | Listen port                                                                                                                              | 4730                            |
| QUEUE_TYPE                            | Persistent queue type to use                                                                                                             | builtin                         |
| THREADS                               | Number of I/O threads to use                                                                                                             | 4                               |
| BACKLOG                               | Number of backlog connections for listen                                                                                                 | 32                              |
| FILE_DESCRIPTORS                      | Number of file descriptors to allow for the process                                                                                      | Default is max allowed for user |
| JOB_RETRIES                           | Number of retries after a failed job. Use -1 for no limit, 0 for no retries, or 1-255 for a bounded number.                              | -1                              |
| WORKER_WAKEUP                         | Number of workers to wakeup for each job received                                                                                        | 0                               |
| KEEPALIVE                             | Enable keepalive on sockets                                                                                                              | 0                               |
| KEEPALIVE_IDLE                        | The duration between two keepalive transmissions in idle condition                                                                       | 300                             |
| KEEPALIVE_INTERVAL                    | The duration between two successive keepalive retransmissions, if acknowledgement to the previous keepalive transmission is not received | 30                              |
| KEEPALIVE_COUNT                       | The number of retransmissions to be carried out before declaring that remote end is not available                                        | 5                               |
| MYSQL_HOST                            | MySQL server host                                                                                                                        | localhost                       |
| MYSQL_PORT                            | MySQL server port                                                                                                                        | 3306                            |
| MYSQL_USER                            | MySQL server user                                                                                                                        | root                            |
| MYSQL_PASSWORD                        | MySQL password                                                                                                                           |                                 |
| MYSQL_PASSWORD_FILE                   | Path to file with MySQL password (Docker secrets)                                                                                        |                                 |
| MYSQL_DB                              | Database to use by Gearman                                                                                                               | Gearmand                        |
| MYSQL_TABLE                           | Table to use by Gearman                                                                                                                  | gearman_queue                   |
| MARIADB_TLS_DISABLE_PEER_VERIFICATION | Allow an unencrypted MySQL queue connection when the database server does not support TLS                                                |                                 |

Gearman 2.x always uses round-robin scheduling and no longer provides a way to
disable it. The deprecated `ROUND_ROBIN` environment variable is ignored and
produces a warning when set.

Gearman 2.1 changed `--job-retries=0` from unlimited retries to no retries. The
image now uses `-1` by default to preserve its previous unlimited-retry
behavior. Users that explicitly set `JOB_RETRIES=0` must change it to `-1` if
they want jobs to continue retrying without a limit.

Keepalive remains opt-in. When `KEEPALIVE` is enabled, the defaults above match
the production values recommended in the [Gearman 2.0.0 release notes][2.0.0].

You can also inject your version of config file to `/etc/gearmand.conf` as needed.

## Release process

To create a new release, run the following command, replacing `VERSION` with the
desired version (which must match a directory for the build context in this
repository), e.g. `2.1.0`:

    gh workflow run release.yml --field version=VERSION

Beginning with Gearman 2.0.0, packaging-only rebuilds keep the upstream version
and append a release suffix, starting with `-r1` (for example, `2.1.0-r1`).
Gearman 1.x images retain the legacy dotted scheme (for example, `1.1.22.1`).
See [CONTRIBUTING.md](CONTRIBUTING.md) for the versioning policy.

This command will automatically build and publish the images, create a git tag,
and publish a GitHub release.

## Credits

See the [list of contributors](https://github.com/artefactual-labs/docker-gearmand/graphs/contributors).

Thanks to @Mararok for the new entry point bringing support for environment variables and secrets.
