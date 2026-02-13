FROM ubuntu:24.04 AS build
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git libssl-dev zlib1g-dev make gcc ca-certificates && \
    git clone https://github.com/ton-bypass/MTProxy && \
    cd MTProxy && make STATIC=1 && \
    rm -rf /var/lib/apt/lists/*
FROM ubuntu:24.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends  \
    curl iproute2 ca-certificates && \
    mkdir /etc/telegram && rm -rf /var/lib/apt/lists/*
COPY --from=build /MTProxy/objs/bin/mtproto-proxy /usr/bin/mtproxyd
COPY run.sh /
CMD ["/bin/bash", "-c", "/run.sh"]
