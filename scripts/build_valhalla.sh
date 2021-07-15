#!/usr/bin/env bash

url="https://valhalla_src:SdV2_QWwQ4zTByySZ8_8@gitlab.ifpen.fr/R1130/VHG/valhalla/valhalla_src.git"
NPROC=$(nproc)

# set proxy
ENV http_proxy=http://irproxy:8082/
ENV https_proxy=http://irproxy:8082/
ENV no_proxy=.ifp.fr,.ifpen.fr
ENV HTTP_PROXY=http://irproxy:8082/
ENV HTTPS_PROXY=http://irproxy:8082/
ENV NO_PROXY=.ifp.fr,.ifpen.fr

git clone $url valhalla_git

# unset proxy
ENV http_proxy=
ENV https_proxy=
ENV no_proxy=
ENV HTTP_PROXY=
ENV HTTPS_PROXY=
ENV NO_PROXY=


cd valhalla_git
git fetch --tags
git checkout "${1}"
git submodule sync
git submodule update --init --recursive
curl -o- curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh" # This loads nvm
nvm install 12.16.1 && nvm use 12.16.1
npm install --ignore-scripts --unsafe-perm=true
ln -s ~/.nvm/versions/node/v12.16.1/include/node/node.h /usr/include/node.h
ln -s ~/.nvm/versions/node/v12.16.1/include/node/uv.h /usr/include/uv.h
ln -s ~/.nvm/versions/node/v12.16.1/include/node/v8.h /usr/include/v8.h
mkdir build
cmake -H. -Bbuild \
  -DCMAKE_C_FLAGS:STRING="${CFLAGS}" \
  -DCMAKE_CXX_FLAGS:STRING="${CXXFLAGS}" \
  -DCMAKE_EXE_LINKER_FLAGS:STRING="${LDFLAGS}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DENABLE_DATA_TOOLS=On \
  -DENABLE_PYTHON_BINDINGS=On \
  -DENABLE_NODE_BINDINGS=On \
  -DENABLE_SERVICES=On \
  -DENABLE_HTTP=On
cd build
make -j"$NPROC"
make -j"$NPROC" check
make install
