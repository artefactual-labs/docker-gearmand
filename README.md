# gearmand
[![](https://images.microbadger.com/badges/image/artefactual/gearmand.svg)](https://microbadger.com/images/artefactual/gearmand)

`artefactual/gearmand` packages recent versions of gearmand using Alpine Linux as the base image.

## Supported tags and respective `Dockerfile` links

- [`1.1.15-alpine` (*Dockerfile*)](https://github.com/artefactual-labs/docker-gearmand/tree/master/1.1.15/Dockerfile)
- [`1.1.16-alpine` (*Dockerfile*)](https://github.com/artefactual-labs/docker-gearmand/tree/master/1.1.16/Dockerfile)
- [`1.1.17-alpine` (*Dockerfile*)](https://github.com/artefactual-labs/docker-gearmand/tree/master/1.1.17/Dockerfile)
- [`1.1.18-alpine`, `latest` (*Dockerfile*)](https://github.com/artefactual-labs/docker-gearmand/tree/master/1.1.18/Dockerfile)

See also the [official releases](https://github.com/gearman/gearmand/releases) page.

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

Supported environment variables configuration(for more info check [http://gearman.info/gearmand.html](http://gearman.info/gearmand.html)):

| Name                | Description                                                                                                                              | Default                         |
|---------------------|------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------|
| VERBOSE             | Logging level                                                                                                                            | INFO                            |
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
| MYSQL_HOST          | Mysql server host                                                                                                                        | localhost                       |
| MYSQL_PORT          | Mysql server port                                                                                                                        | 3306                            |
| MYSQL_USER          | Mysql server user                                                                                                                        | root                            |
| MYSQL_PASSWORD      | Mysql password                                                                                                                           |                                 |
| MYSQL_PASSWORD_FILE | Path to file with mysql password(Docker secrets)                                                                                         |                                 |
| MYSQL_DB            | Database to use by Gearman                                                                                                               | Gearmand                        |
| MYSQL_TABLE         | Table to use by Gearman                                                                                                                  | gearman_queue                   |

You can also inject your version of config file to `/etc/gearmand.conf` as needed.
