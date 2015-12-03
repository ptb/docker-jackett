FROM alpine:3.2
# MAINTAINER Peter T Bosse II <ptb@ioutime.com>

RUN \
  REQUIRED_PACKAGES="mono curl-dev" \
  && BUILD_PACKAGES="wget" \

  && USERID_ON_HOST=1026 \

  && adduser -D -G users -g Jackett -s /sbin/nologin -u $USERID_ON_HOST jackett \

  && apk add --update-cache \
    --repository http://dl-2.alpinelinux.org/alpine/edge/testing/ \
    $REQUIRED_PACKAGES \
    $BUILD_PACKAGES \

  && mkdir -p /app/ \
  && wget \
    --output-document - \
    --quiet \
    https://api.github.com/repos/Jackett/Jackett/releases/latest \
    | sed -n "s/^.*browser_download_url.*: \"\(.*Jackett.Binaries.Mono.tar.gz\)\".*/\1/p" \
    | wget \
      --input-file - \
      --output-document - \
      --quiet \
    | tar -xz -C /app/ \

  && wget \
    --output-document - \
    --quiet \
    https://api.github.com/repos/just-containers/s6-overlay/releases/latest \
    | sed -n "s/^.*browser_download_url.*: \"\(.*s6-overlay-amd64.tar.gz\)\".*/\1/p" \
    | wget \
      --input-file - \
      --output-document - \
      --quiet \
    | tar -xz -C / \

  && mkdir -p /etc/services.d/jackett/ \
  && printf "%s\n" \
    "#!/usr/bin/env sh" \
    "set -ex" \
    "exec s6-applyuidgid -g 100 -u $USERID_ON_HOST \\" \
    "  /usr/bin/mono /app/Jackett/JackettConsole.exe" \
    > /etc/services.d/jackett/run \
  && chmod +x /etc/services.d/jackett/run \

  && apk del \
    $BUILD_PACKAGES \
  && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

ENTRYPOINT ["/init"]
EXPOSE 9117

# docker build --rm --tag ptb2/jackett .
# docker run --detach --name jackett --net host \
#   --publish 9117:9117/tcp \
#   --volume /volume1/@appstore/Jackett:/home/jackett/.config \
#   ptb2/jackett
