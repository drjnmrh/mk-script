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

if [[ ! -d "$PREFIX/downloaded" ]]; then
    mkdir -p $PREFIX/downloaded
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(Prepare)\n"
        mk::exit 1
    fi
fi

cd $PREFIX/downloaded

if [[ ! -d "glew-2.2.0" ]]; then
    mk::info "Downloading GLEW v2.2.0...\n"
    curl -OL https://github.com/nigels-com/glew/releases/download/glew-2.2.0/glew-2.2.0.tgz
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(Download)\n"
        mk::exit 1
    fi
    mk::done "DONE(Download)\n"

    mk::info "Unpacking glew-2.2.0... "
    tar -xf glew-2.2.0.tgz
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(Unpack)\n"
        mk::exit 1
    fi
    mk::done "DONE(Unpacking)\n"
fi
cd glew-2.2.0
cd build

mk::info "Generating Makefiles using CMake...\n"
cmake ./cmake -DCMAKE_INSTALL_PREFIX=$PREFIX/Unix-x86_64
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(Generate)\n"
    mk::exit 1
fi
mk::done "DONE(Generate)\n"

mk::info "Building...\n"
make -j4
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(Build)\n"
    mk::exit 1
fi
mk::done "DONE(Build)\n"

mk::info "Installing...\n"
make install
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(Install)\n"
    mk::exit 1
fi
mk::done "DONE(Install)\n"

mk::exit 0
