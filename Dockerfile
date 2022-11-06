# Dockerfile for Tor Relay Server with obfs4proxy
FROM debian:bullseye
RUN echo 'deb http://deb.debian.org/debian bullseye-backports main' > /etc/apt/sources.list.d/backports.list
MAINTAINER Josh josh.gaby@gmail.com

ARG GPGKEY=A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="True"
ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND=noninteractive
ARG found=""

# Set a default Nickname
ENV TOR_NICKNAME=Tor4
ENV TOR_USER=tord
ENV TERM=xterm

# Install tor with GeoIP and obfs4proxy & backup torrc
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        apt-utils \
 && apt-get install -y \
        pwgen \
        iputils-ping \
        tor/bullseye-backports \
        tor-geoipdb/bullseye-backports \
        obfs4proxy/bullseye-backports \
 && mkdir -pv /usr/local/etc/tor/ \
 && mv -v /etc/tor/torrc /usr/local/etc/tor/torrc.sample \
 && apt-get purge --auto-remove -y \
        apt-utils \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 # Rename Debian unprivileged user to tord \
 && usermod -l ${TOR_USER} debian-tor \
 && groupmod -n ${TOR_USER} debian-tor

# Copy Tor configuration file
COPY ./torrc /etc/tor/torrc

# Copy docker-entrypoint
COPY ./scripts/ /usr/local/bin/

# Persist data
VOLUME /etc/tor /var/lib/tor

# ORPort, DirPort, SocksPort, ObfsproxyPort, MeekPort
EXPOSE 9001 9030 9050 54444 7002

ENTRYPOINT ["docker-entrypoint"]
CMD ["tor", "-f", "/etc/tor/torrc"]
