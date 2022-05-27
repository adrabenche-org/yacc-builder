FROM --platform=linux/amd64 haskell:8.10.7 AS cardano-cli-builder
MAINTAINER alejandro.drabenche@line64.com

ARG GIT_NODE_REV
ENV LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/include:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:/usr/include/pkgconfig:$PKG_CONFIG_PATH"

# Installing packages
RUN echo "deb [arch=amd64] http://ftp.de.debian.org/debian bullseye main" >>  /etc/apt/sources.list.d/cardano.list 
RUN apt-get -y upgrade && apt-get update -y && \
    apt-get install -y  git jq bc make automake rsync htop curl build-essential \
    pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev \
    make g++ wget libncursesw5 libtool autoconf libsodium-dev libghc-microlens-th-dev libsecp256k1-dev
RUN apt-get clean

# Cloning the Repo
WORKDIR /cardano-cli
RUN git config --global init.defaultBranch main &&  \
    git config --global advice.detachedHead false && \
    git init && \
    git remote add origin  https://github.com/input-output-hk/cardano-node.git && \
    git fetch  && \
    test -z ${GIT_NODE_REV} &&  git checkout $(git describe --tags $(git rev-list --tags --max-count=1)) || git checkout ${GIT_NODE_REV} 

# Building the cardano-cli binary
RUN cabal update
RUN echo "package cardano-crypto-praos\n flags: -external-libsodium-vrf\n optimization: 2\n tests: False" >> cabal.project 
RUN cabal build --project-file=cabal.project cardano-cli
RUN cp -p "$(./scripts/bin-path.sh cardano-cli)" /tmp/

FROM --platform=linux/amd64 debian:bullseye-slim

ENV LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/include:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:/usr/include/pkgconfig:$PKG_CONFIG_PATH"

RUN apt-get update && apt-get install -y libsodium-dev

COPY --from=cardano-cli-builder /tmp/cardano-cli /usr/local/bin
ENTRYPOINT ["/usr/local/bin/cardano-cli"]
