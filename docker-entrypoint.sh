#!/bin/sh
set -e

chown -R postgres "$PGDATA"
chmod 0700 "$PGDATA"

# Bomb out if no password set
: ${POSTGRES_PASSWORD:?}
: ${POSTGRES_REPLICATION:="no"}
: ${POSTGRES_REPLICATION_USER:="replication"}
: ${POSTGRES_REPLICATION_PASSWORD:="$POSTGRES_PASSWORD"}

if [ -z "$(ls -A "$PGDATA")" ]; then
    if [ "$POSTGRES_REPLICATION" = "slave" ] ; then
        : ${POSTGRES_REPLICATION_MASTER_HOST:?}
        : ${POSTGRES_REPLICATION_MASTER_PORT:=5432}
        echo "$POSTGRES_REPLICATION_MASTER_HOST:$POSTGRES_REPLICATION_MASTER_PORT:replication:$POSTGRES_REPLICATION_USER:$POSTGRES_REPLICATION_PASSWORD" > /var/lib/postgresql/.pgpass
        chown postgres /var/lib/postgresql/.pgpass
        chmod 0600 /var/lib/postgresql/.pgpass
        gosu postgres pg_basebackup -h $POSTGRES_REPLICATION_MASTER_HOST -p $POSTGRES_REPLICATION_MASTER_PORT -D "$PGDATA" -R -P -v -w -U $POSTGRES_REPLICATION_USER --xlog-method=stream
        rm /var/lib/postgresql/.pgpass
        echo
    else
        gosu postgres initdb
        sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "$PGDATA"/postgresql.conf

        : ${POSTGRES_USER:="postgres"}
        : ${POSTGRES_DB:=$POSTGRES_USER}

        if [ "$POSTGRES_DB" != 'postgres' ]; then
          createSql="CREATE DATABASE $POSTGRES_DB;"
          echo $createSql | gosu postgres postgres --single -jE
          echo
        fi

        if [ "$POSTGRES_USER" != 'postgres' ]; then
          op=CREATE
        else
          op=ALTER
        fi

        userSql="$op USER $POSTGRES_USER WITH SUPERUSER PASSWORD '${POSTGRES_PASSWORD}';"
        echo $userSql | gosu postgres postgres --single -jE
        echo

        if [ "$POSTGRES_REPLICATION" = "master" ] ; then
            sed -ri "s/^#(wal_level\s*=\s*)\S+/\1hot_standby/" "$PGDATA"/postgresql.conf
            sed -ri "s/^#(max_wal_senders\s*=\s*)\S+/\15/" "$PGDATA"/postgresql.conf
            sed -ri "s/^#(wal_keep_segments\s*=\s*)\S+/\132/" "$PGDATA"/postgresql.conf
            userSql="$op USER $POSTGRES_REPLICATION_USER WITH REPLICATION PASSWORD '${POSTGRES_REPLICATION_PASSWORD}';"
            echo $userSql | gosu postgres postgres --single -jE
            echo
        fi

        # internal start of server in order to allow set-up using psql-client
        # does not listen on TCP/IP and waits until start finishes
        gosu postgres pg_ctl -D "$PGDATA" \
            -o "-c listen_addresses=''" \
            -w start

        echo
        for f in /docker-entrypoint-initdb.d/*; do
            case "$f" in
                *.sh)  echo "$0: running $f"; . "$f" ;;
                *.sql) echo "$0: running $f"; psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" < "$f" && echo ;;
                *)     echo "$0: ignoring $f" ;;
            esac
            echo
        done

        gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop

        { echo; echo "host all all 0.0.0.0/0 md5"; } >> "$PGDATA"/pg_hba.conf
        if [ "$POSTGRES_REPLICATION" = "master" ] ; then
            { echo; echo "host replication $POSTGRES_REPLICATION_USER 0.0.0.0/0 md5"; } >> "$PGDATA"/pg_hba.conf
        fi
    fi
fi

echo 'Starting database'

exec gosu postgres "$@"
