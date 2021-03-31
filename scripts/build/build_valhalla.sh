#!/usr/bin/env bash

set -e

url="https://github.com/guoxifeng1990/valhalla"
NPROC=$(nproc)

git clone $url valhalla_git
cd valhalla_git
git fetch --tags
git checkout "${1}"
git submodule sync
git submodule update --init --recursive
mkdir build
# install to /usr/local so we can copy easily from the builder to the runner
cmake -H. -Bbuild \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_CCACHE=OFF \
  -DENABLE_BENCHMARKS=OFF \
  -DENABLE_TESTS=OFF \
  -DENABLE_TOOLS=ON
make -C build -j"$NPROC"
make -C build install
