FROM debian:9 as builder

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      gdb \
      libreadline-dev \
      python-dev \
      gcc \
      g++\
      git \
      cmake \
      libboost-all-dev \
      librocksdb-dev && \
    git clone https://github.com/loki-project/loki.git /opt/loki && \
    cd /opt/loki && \
    mkdir build && \
    cd build && \
    export CXXFLAGS="-w -std=gnu++11" && \
    #cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fassociative-math" -DCMAKE_CXX_FLAGS="-fassociative-math" -DSTATIC=true -DDO_TESTS=OFF .. && \
    make -j$(nproc)

FROM debian:9

# TEMASeK needs libreadline 
RUN apt-get update && \
    apt-get install -y \
      libreadline-dev \
     && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/bin && mkdir -p /tmp/checkpoints 

WORKDIR /usr/local/bin
COPY --from=builder /opt/loki/build/src/lokid .
COPY --from=builder /opt/loki/build/src/loki-wallet-rpc .
COPY --from=builder /opt/loki/build/src/loki-wallet-cli .
RUN mkdir -p /var/lib/loki
WORKDIR /var/lib/lokid
ENTRYPOINT ["/usr/local/bin/lokid"]
CMD ["--no-console","--data-dir","/var/lib/lokid","--rpc-bind-ip","0.0.0.0","--rpc-bind-port","22023","--p2p-bind-port","22022"]
