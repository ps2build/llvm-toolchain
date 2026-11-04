FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends     build-essential cmake ninja-build git python3 texinfo zip ca-certificates curl     gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 mingw-w64-tools     && rm -rf /var/lib/apt/lists/*
