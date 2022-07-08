FROM --platform=linux/amd64 haskell:8.10.7 AS cardano-cli-builder
MAINTAINER alejandro.drabenche@line64.com

ARG GIT_NODE_REV
ENV LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/include:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:/usr/include/pkgconfig:$PKG_CONFIG_PATH"

# Installing packages
RUN echo "deb [arch=amd64] http://ftp.de.debian.org/debian bullseye main" >>  /etc/apt/sources.list.d/cardano.list 
RUN apt-get -y upgrade && apt-get update -y && \
    apt-get install -y  autoconf automake bc build-essential curl g++ git htop  \
    jq libffi-dev libghc-microlens-th-dev libgmp-dev liblmdb-dev libncursesw5 \
    libssl-dev libsystemd-dev libtinfo-dev libtool llvm-9 dh-autoreconf numactl libnuma-dev \
    make pkg-config rsync tmux wget zlib1g-dev
RUN apt-get clean

# Installing libsecp256k1
WORKDIR /libsecp256k1
RUN git clone https://github.com/bitcoin-core/secp256k1.git  && \
    cd secp256k1  && \
    git reset --hard ac83be33d0956faf6b7f61a60ab524ef7d6a473a  && \
    ./autogen.sh  && \
    ./configure --prefix=/usr --enable-module-schnorrsig --enable-experimental  && \
    make  && \
    make check  && \
    make install

# Installing libsodium
WORKDIR /libsodium
RUN git clone https://github.com/input-output-hk/libsodium   && \
    cd libsodium   && \
    git checkout 66f017f1   && \
    ./autogen.sh   && \
    ./configure   && \
    make   && \
    make install

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
RUN cabal build all
RUN echo "package cardano-crypto-praos\n flags: -external-libsodium-vrf\n optimization: 2\n tests: False" >> cabal.project 
RUN cabal build --project-file=cabal.project cardano-cli
RUN cp -p "$(./scripts/bin-path.sh cardano-cli)" /tmp/

FROM --platform=linux/amd64 debian:bullseye-slim

ENV LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/include:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:/usr/include/pkgconfig:$PKG_CONFIG_PATH"

RUN apt-get update && apt-get install -y autoconf automake bc build-essential curl g++ git htop  \
    jq libffi-dev libghc-microlens-th-dev libgmp-dev liblmdb-dev libncursesw5 \
    libssl-dev libsystemd-dev libtinfo-dev libtool llvm-9 dh-autoreconf numactl libnuma-dev \
    make pkg-config rsync tmux wget zlib1g-dev

# Installing libsecp256k1
WORKDIR /libsecp256k1
RUN git clone https://github.com/bitcoin-core/secp256k1.git  && \
    cd secp256k1  && \
    git reset --hard ac83be33d0956faf6b7f61a60ab524ef7d6a473a  && \
    ./autogen.sh  && \
    ./configure --prefix=/usr --enable-module-schnorrsig --enable-experimental  && \
    make  && \
    make check  && \
    make install

# Installing libsodium
WORKDIR /libsodium
RUN git clone https://github.com/input-output-hk/libsodium   && \
    cd libsodium   && \
    git checkout 66f017f1   && \
    ./autogen.sh   && \
    ./configure   && \
    make   && \
    make install

COPY --from=cardano-cli-builder /tmp/cardano-cli /usr/local/bin
ENTRYPOINT ["/usr/local/bin/cardano-cli"]
