FROM golang:1-alpine

MAINTAINER Sullivan SENECHAL <soullivaneuh@gmail.com>

RUN apk add --no-cache \
bash openrc rsyslog mysql-client gcc musl-dev openssl-dev libtool

RUN apk add --no-cache --virtual .build-deps \
tar git \
&& go get github.com/jsha/listenbuddy \
&& go get bitbucket.org/liamstask/goose/cmd/goose \
&& mkdir -p /go/src/github.com/letsencrypt/boulder && cd /go/src/github.com/letsencrypt/boulder \
&& curl -L https://github.com/letsencrypt/boulder/archive/master.tar.gz | tar xz --strip-components 1 \
&& apk del .build-deps

ENV BOULDER_CONFIG /go/src/github.com/letsencrypt/boulder/test/boulder-config.json
ENV GOPATH /go/src/github.com/letsencrypt/boulder/Godeps/_workspace:$GOPATH

RUN echo $GOPATH

WORKDIR /go/src/github.com/letsencrypt/boulder

RUN sed -i -e 's#0.0.0.0/3306#mariadb/3306#' -e 's#0.0.0.0/5672#rabbitmq/5672#' -e 's#amqp://localhost#amqp://rabbitmq#' test/entrypoint.sh
RUN sed -i -e 's#127.0.0.1#mariadb#' test/create_db.sh
# https://github.com/letsencrypt/boulder/issues/1322
RUN sed -i "1s/^/SET sql_mode = '';\n/" test/drop_users.sql

EXPOSE 4000
ENTRYPOINT ["./test/entrypoint.sh"]
CMD ["./start.py"]
