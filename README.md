Database container
==

Forked and tweaked from [kiasaki/docker-alpine-postgres](//github.com/kiasaki/docker-alpine-postgres)

Build
--

```bash
$ docker build -t quay.io/cluster_mailboxes/docker-alpine-postgres:latest .
$ docker push quay.io/cluster_mailboxes/docker-alpine-postgres:latest
```

Running
--

```bash
$ docker run -e POSTGRES_PASSWORD='something' POSTGRES_USER='bilbo' POSTGRES_DB='someshite' quay.io/cluster_mailboxes/docker-alpine-postgres:latest
```

License
--

MIT. See `LICENSE` file.
