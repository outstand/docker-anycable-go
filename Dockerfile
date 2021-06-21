FROM golang:alpine as build

RUN apk add --no-cache build-base git

WORKDIR /go/src/anycable-go
RUN git clone https://github.com/outstand/anycable-go.git .
RUN git checkout allow-tls && \
      rm -f .dockerignore

ENV MODIFIER=tls
RUN make build-linux

FROM alpine:latest
LABEL maintainer="Ryan Schlesinger <ryan@outstand.com>"

RUN apk add --no-cache ca-certificates bash curl jq su-exec

COPY --from=build /go/src/anycable-go/dist/anycable-go-v1.1.1-linux-amd64 /usr/local/bin/anycable-go

COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]
