# PostgreSQL docker image based on Alpine Linux with streamed replication support

This repo builds a docker image that accepts the same env vars as the
[official postgres build](https://registry.hub.docker.com/_/postgres/) but
with a much smaller footprint. It achieves that by basing itself off the great
[alpine](https://github.com/gliderlabs/docker-alpine) docker image by GliderLabs.

## Why?

```bash
$ docker images
REPOSITORY          TAG         VIRTUAL SIZE
alpine-postgres     latest      22.28 MB
postgres            latest      213.90 MB
```

# Build

```bash
$ make build
```

# Usage

This image works in the same way the official `postgres` docker image work.

It's documented on DockerHub in it's README: [https://hub.docker.com/_/postgres/](https://hub.docker.com/_/postgres/).

For example, you can start a basic PostgreSQL server, protected by a password,
listening on port 5432 by running the following:

```
$ docker run --name some-postgres -e POSTGRES_PASSWORD=mysecretpassword -d alpine-postgres
```

Next, you can start you app's container while **linking** it to the PostgreSQL
container you just created giving it access to it.

```
$ docker run --name some-app --link some-postgres:postgres -d application-that-uses-postgres
```

Your app will now be able to access `POSTGRES_PORT_5432_TCP_ADDR` and `POSTGRES_PORT_5432_TCP_PORT` environment variables.

# Streamed replication

Since postgres needs as much HDD IO speed as possible, network storage solutions can be a big bottleneck. Using host directories is
a fast solution. The easiest way to add redundancy in such a situation is to use streamed replication.

## Master setup

To enable replication on a new master installation, set `POSTGRES_REPLICATION` to `master`.
By default `POSTGRES_REPLICATION_USER` is set to `replication` and `POSTGRES_REPLICATION_PASSWORD` is set to `POSTGRES_PASSWORD`.

The config variables `wal_level`, `max_wal_senders` and `wal_keep_segments` are modified in the new `postgresql.conf` config file.

## Client setup

Set `POSTGRES_REPLICATION` to `slave` and `POSTGRES_REPLICATION_MASTER_HOST` to the hostname/IP of the current master server.
`POSTGRES_REPLICATION_MASTER_PORT` defaults to 5432 which should fit in most situations.

The `PGDATA` directory have to be empty to start the initial replication. The replication is done via the tool `pg_basebackup`.

Note that the initial backup can take some time, depending on the database size.

# License

MIT. See `LICENSE` file.