#!/bin/bash

PREFIX=$1
MKSCRIPT_PATH=$2

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

TOOLCHAIN=$MKSCRIPT_PATH/examples/cross-platform-smile/scripts/iOS-toolchain.cmake
if [[ ! -e "$TOOLCHAIN" ]]; then
    mk::err "No toolchain file $TOOLCHAIN!"
    mk::fail "Invalid path to mk-script repo\n"
    mk::exit 1
fi

if [[ ! -d "$PREFIX" ]]; then
    mk::info "Prepare $PREFIX folder... "
    mkdir -p $PREFIX
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED\n"
        mk::exit 1
    fi
    mk::done "DONE\n"
fi

mkdir -p $PREFIX/downloaded

cd $PREFIX/downloaded

if [[ ! -d "$PREFIX/downloaded/libpng-1.6.43" ]]; then
    mk::info "Downloading libpng-1.6.43...\n"
    curl -LO https://sourceforge.net/projects/libpng/files/libpng16/1.6.43/libpng-1.6.43.tar.gz
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED\n"
        mk::exit 1
    fi
    mk::done "DONE\n"

    mk::info "Untar downloaded archive... "
    tar -xzvf libpng-1.6.43.tar.gz
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED\n"
        mk::exit 1
    fi
    mk::done "DONE\n"
fi

cd libpng-1.6.43
mkdir build-osx
cd build-osx

_arch=$(uname -m)
mk::info "Generating using CMake for $_arch...\n"
cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX/osx-$_arch -DPNG_SHARED=OFF
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(CMake MacOSX)\n"
    mk::exit 1
fi

mk::info "Building libpng static library...\n"
cmake --build . --config Release
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(Build MacOSX)\n"
    mk::exit 1
fi

mk::info "Installing libpng...\n"
make install
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(Install MacOSX)\n"
    mk::exit 1
fi

cd ..
mkdir build-iphone
cd build-iphone

mk::info "Generating using CMake for iPhone...\n"
_toolchain="-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN"
_iosversion="-DIOS_MINIMUM_VERSION=15.2"
cmake .. $_iosversion $_toolchain -DIOS_TYPE=iphone -DCMAKE_INSTALL_PREFIX=$PREFIX/iphone -DPNG_SHARED=NO -DPNG_FRAMEWORK=NO
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(CMake iPhone)\n"
    mk::exit 1
fi

mk::info "Building for iPhone...\n"
cmake --build . --config Release
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(Build iPhone)\n"
    mk::exit 1
fi

mk::info "Installing for iPhone...\n"
make install
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED(Install iPhone)\n"
    mk::exit 1
fi
mk::exit 0
