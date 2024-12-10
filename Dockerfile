# Dockerfile for Tor Relay Server with obfs4proxy
FROM debian:bookworm
LABEL org.opencontainers.image.authors="josh.gaby@gmail.com"

# Set a default Nickname
ENV TOR_NICKNAME=Tor4
ENV TOR_USER=tord
ENV TERM=xterm

# Install tor with GeoIP and obfs4proxy & backup torrc
RUN apt-get update \
    && apt-get install -y apt-transport-https wget gpg \
    && apt-get install -y unattended-upgrades apt-listchanges

COPY tor.sources.list /etc/apt/sources.list.d/tor.list
COPY 50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
COPY 20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades

RUN wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null
RUN apt-get update \
    && apt-get install -y tor deb.torproject.org-keyring\
    && apt-get install -y pwgen \
    && apt-get install -y tor-geoipdb \
    && apt-get install -y obfs4proxy \
    && mkdir -pv /usr/local/etc/tor/ \
    && apt-get -y purge --auto-remove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Rename Debian unprivileged user to tord \
RUN usermod -l ${TOR_USER} debian-tor \
    && groupmod -n ${TOR_USER} debian-tor

COPY torrc /etc/tor/torrc
COPY ./scripts/ /usr/local/bin/

# Persist data
VOLUME /etc/tor /var/lib/tor

# ORPort, DirPort, SocksPort, ObfsproxyPort
EXPOSE 9001 9030 9050 54444

ENTRYPOINT ["docker-entrypoint"]
CMD ["tor", "-f", "/etc/tor/torrc"]
