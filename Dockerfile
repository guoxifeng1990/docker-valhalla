FROM ubuntu:20.04 as builder
MAINTAINER Nils Nolde <nils@gis-ops.com>

# Set docker specific settings
ENV TERM xterm

# Install deps
RUN echo "Installing dependencies..." && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update > /dev/null && apt-get update --fix-missing > /dev/null && \
    apt-get install -y \
        # prime_server requirements
        automake locales autoconf pkg-config build-essential lcov libcurl4-openssl-dev git-core libzmq3-dev libczmq-dev \
        # Valhalla requirements
        apt-utils cmake curl wget unzip jq python3.8-dev \
        ca-certificates gnupg2 parallel spatialite-bin libtool \
        zlib1g-dev libsqlite3-mod-spatialite libgeos-dev libgeos++-dev libprotobuf-dev \
        protobuf-compiler libboost-all-dev libsqlite3-dev libspatialite-dev libluajit-5.1-dev \
      > /dev/null && \
    locale-gen en_US.UTF-8 && \
    # set paths to fix the libspatialite error
    ln -s /usr/lib/x86_64-linux-gnu/mod_spatialite.so /usr/lib/mod_spatialite && \
    # Create necessary folders
    mkdir -p /valhalla/scripts /valhalla/conf/valhalla_tiles

# Set language
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Export path variables
ENV SCRIPTS_DIR ${SCRIPTS_DIR:-"/valhalla/scripts"}
ENV CONFIG_PATH ${CONFIG_PATH:-"/valhalla/conf/valhalla.json"}

WORKDIR /valhalla/

# Copy all necessary build scripts
COPY scripts/build/. ${SCRIPTS_DIR}

ARG PRIMESERVER_RELEASE=master
RUN echo "Installing prime_server..." && \
    /bin/bash ${SCRIPTS_DIR}/build_prime_server.sh ${PRIMESERVER_RELEASE}

# Build Valhalla
ARG VALHALLA_RELEASE=dev
RUN echo "Installing Valhalla..." && \
    /bin/bash ${SCRIPTS_DIR}/build_valhalla.sh ${VALHALLA_RELEASE} && \
    cp -r /valhalla/valhalla_git/scripts/. ${SCRIPTS_DIR}

# Second stage
FROM ubuntu:20.04 as runner

COPY --from=builder /usr/local /usr/local
COPY --from=builder /valhalla/scripts /valhalla/scripts
COPY --from=builder /valhalla/conf /valhalla/conf

RUN apt-get update > /dev/null && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y libboost-program-options1.71.0 libluajit-5.1-2 \
      libzmq3-dev libczmq-dev spatialite-bin libprotobuf-lite17 \
      libsqlite3-0 libsqlite3-mod-spatialite libgeos-3.8.0 libcurl4 \
      python3.8-minimal curl unzip parallel jq && \
    ln -s /usr/bin/python3.8 /usr/bin/python && \
    ln -s /usr/bin/python3.8 /usr/bin/python3 && \
    # python-minimal doesn't set up dist-packages
    # for now, also create the valhalla package manually
    mkdir -p /usr/lib/python3.8/dist-packages/valhalla && \
    echo "from python_valhalla import *" > /usr/lib/python3.8/dist-packages/valhalla/__init__.py

# copy python bindings separately as they need to be in /usr
COPY --from=builder /usr/local/lib/python3.8/dist-packages/python_valhalla.cpython-38-x86_64-linux-gnu.so /usr/lib/python3.8/dist-packages
COPY scripts/runtime/. /valhalla/scripts

# Expose the necessary port
EXPOSE 8002
CMD /valhalla/scripts/run.sh

