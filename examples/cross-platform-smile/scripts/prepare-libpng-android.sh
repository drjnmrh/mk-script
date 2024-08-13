#!/bin/bash

PREFIX=$1
ARCHS=(arm64-v8a armeabi-v7a x86_64)

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

if [[ ! -e "$NDK_HOME/build/ndk-build" ]]; then
    mk::err "Couldn't file NDK in NDK_HOME='$NDK_HOME'"
    mk::fail "Invalid NDK_HOME value\n"
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
if [[ ! -d "$PREFIX/downloaded/libpng-android" ]]; then
    mk::info "Cloning libpng-android repo...\n"
    git clone https://github.com/julienr/libpng-android.git

    if [[ ! -d "libpng-android" ]]; then
        mk::fail "FAILED\n"
        mk::exit 1
    fi
    mk::done "DONE\n"
fi

cd libpng-android

export PATH=$NDK_HOME/build:$PATH

mk::info "Building...\n"
./build.sh
if [[ $? -ne 0 ]]; then
    mk::fail "FAILED\n"
    mk::exit 1
fi
mk::done "DONE\n"

mk::info "Prepare output folders...\n"

for _arch in "${ARCHS[@]}"
do
    mk::info "- $_arch: "
    mkdir -p $PREFIX/android/$_arch/include
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(include)\n"
        mk::exit 1
    fi
    mk::done "include, "

    mkdir -p $PREFIX/android/$_arch/lib
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(lib)\n"
        mk::exit 1
    fi
    mk::done "lib, "

    cp obj/local/$_arch/libpng.a $PREFIX/android/$_arch/lib
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(libpng.a)\n"
        mk::exit 1
    fi
    mk::done "libpng.a, "

    cp jni/*.h $PREFIX/android/$_arch/include
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(headers)\n"
        mk::exit 1
    fi
    mk::done "headers;\n"
done

mk::exit 0

