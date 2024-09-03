#!/bin/bash

PREFIX=$1

MYDIR="$(cd "$(dirname "$0")" && pwd)"
OLDDIR=${PWD}

mk::fail() { printf "\033[31m$1\033[0m" ${@:2}; }
mk::info() { printf "\033[34m$1\033[0m" ${@:2}; }
mk::warn() { printf "\033[33m$1\033[0m" ${@:2}; }
mk::done() { printf "\033[32m$1\033[0m" ${@:2}; }
mk::err()  { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2; }

mk::exit() {
    cd $MYDIR
    if [[ $? -ne 0 ]]; then
        mk::err "Something has gone horribly wrong!"
        mk::fail "FAILED\n"
        exit 1
    fi

    exit $1
}

if [[ ! -d "$PREFIX" ]]; then
    mk::info "Prepare $PREFIX folder... "
    mkdir -p $PREFIX
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED\n"
        mk::exit 1
    fi
    mk::done "DONE\n"
fi

cd $PREFIX

mkdir downloaded
cd downloaded

if [[ ! -d "$PREFIX/downloaded/glm-1.0.1" ]]; then
    mk::info "Download glm-1.0.1...\n"
    curl -OL https://github.com/g-truc/glm/archive/refs/tags/1.0.1.tar.gz
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(download)\n"
        mk::exit 1
    fi

    mv 1.0.1.tar.gz glm-1.0.1.tar.gz
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(rename)\n"
        mk::exit 1
    fi

    tar -xf glm-1.0.1.tar.gz
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(untar)\n"
        mk::exit 1
    fi
    mk::done "DONE\n"
fi

cd glm-1.0.1
mkdir build
cd build

mk::info "Generate using CMake...\n"
cmake .. -DGLM_BUILD_TESTS=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$PREFIX
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(CMake)\n"
    mk::exit 1
fi
mk::done "DONE\n"

mk::info "Building...\n"
cmake --build . -- all
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(Build)\n"
    mk::exit 1
fi
mk::done "DONE\n"

mk::info "Installing...\n"
cmake --build . -- install
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(Install)\n"
    mk::exit 1
fi
mk::done "DONE\n"

mk::exit 0

