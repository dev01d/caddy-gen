FROM golang:alpine3.20 AS build

ARG DOCKER_GEN_VERSION="0.14.0"
ARG FOREGO_VERSION="0.16.1"
ARG TARGETARCH

# Install all dependenices:
RUN apk update && apk upgrade \
  && apk add --no-cache bash openssh-client git \
  && apk add --no-cache --virtual .build-dependencies curl wget tar \
  && apk del .build-dependencies
# Install Forego
RUN GOBIN=/usr/bin go install github.com/jwilder/forego@v${FOREGO_VERSION}
# Install docker-gen
RUN wget --quiet "https://github.com/nginx-proxy/docker-gen/releases/download/${DOCKER_GEN_VERSION}/docker-gen-alpine-linux-${TARGETARCH}-${DOCKER_GEN_VERSION}.tar.gz" \
  && tar -C /usr/bin -xvzf "docker-gen-alpine-linux-${TARGETARCH}-${DOCKER_GEN_VERSION}.tar.gz"


FROM caddy:2.9.1-alpine AS app

ENV CADDYPATH="/etc/caddy"
ENV DOCKER_HOST="unix:///tmp/docker.sock"

# Install all dependenices:
RUN apk update && apk upgrade \
  && apk add --no-cache bash

COPY --from=build /usr/bin/forego /usr/bin/forego
COPY --from=build /usr/bin/docker-gen /usr/bin/docker-gen

EXPOSE 80 443 2015
VOLUME /etc/caddy

# Starting app:
COPY . /code
COPY ./docker-gen/templates/Caddyfile.tmpl /code/docker-gen/templates/Caddyfile.bkp
WORKDIR /code

ENTRYPOINT ["sh", "/code/docker-entrypoint.sh"]
CMD ["/usr/bin/forego", "start", "-r"]
