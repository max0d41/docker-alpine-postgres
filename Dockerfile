FROM alpine:edge

RUN apk update && apk add curl postgresql=9.5.0-r0 postgresql-contrib=9.5.0-r0 && \
    mkdir /docker-entrypoint-initdb.d && \
    curl -o /usr/local/bin/gosu -sSL "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64" && \
    chmod +x /usr/local/bin/gosu && \
    apk del curl && \
    rm -rf /var/cache/apk/*

ENV LANG en_GB.utf8
ENV PGDATA /var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]
