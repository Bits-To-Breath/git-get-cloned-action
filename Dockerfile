FROM alpine:latest

RUN apk add --no-cache bash
RUN apk add --no-cache git
RUN apk add --no-cache curl
RUN apk add --no-cache perl
RUN apk add --no-cache jq

COPY entrypoint.sh /entrypoint.sh
COPY reg.pl /reg.pl
ENTRYPOINT ["/bin/bash", "-c", "/entrypoint.sh"]
