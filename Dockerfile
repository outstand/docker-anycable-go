FROM anycable/anycable-go:1.1.1-alpine as anycable

FROM alpine:latest
LABEL maintainer="Ryan Schlesinger <ryan@outstand.com>"

RUN apk add --no-cache ca-certificates bash curl jq

COPY --from=anycable /usr/local/bin/anycable-go /usr/local/bin/anycable-go
COPY --from=anycable /etc/passwd /etc/passwd

COPY docker-entrypoint.sh /docker-entrypoint.sh

USER nobody
EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]
