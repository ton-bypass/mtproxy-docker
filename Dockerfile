FROM fedora:28 AS build
RUN dnf install -y git openssl-devel zlib-devel make gcc && \
    git clone https://github.com/TelegramMessenger/MTProxy && \
    cd MTProxy && make
FROM fedora:28
RUN dnf upgrade -y zlib openssl && dnf install -y iproute && mkdir /etc/telegram && dnf clean all
COPY --from=build /MTProxy/objs/bin/mtproto-proxy /usr/bin/mtproxyd
COPY run.sh /
CMD ["/bin/bash", "-c", "/run.sh"]
