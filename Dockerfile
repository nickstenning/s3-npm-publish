FROM alpine:3.5

RUN apk add --no-cache \
    jq \
    nodejs \
    python \
    py-pip \
  && pip install --no-cache-dir awscli \
  && mkdir /src

ADD publish /usr/local/bin/publish

WORKDIR /src

ENTRYPOINT ["publish"]
