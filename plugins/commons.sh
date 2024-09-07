#!/bin/bash

OLDWD=$(pwd)

MYDIR="$(cd "$(dirname "$0")" && pwd)"
OLDDIR=${PWD}

VERBOSE=0


mk::fail() { printf "\033[31m$1\033[0m" ${@:2}; }
mk::info() { printf "\033[34m$1\033[0m" ${@:2}; }
mk::warn() { printf "\033[33m$1\033[0m" ${@:2}; }
mk::done() { printf "\033[32m$1\033[0m" ${@:2}; }
mk::err()  { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2; }

mk::debug() {
    if [[ $VERBOSE -eq 1 ]]; then
        printf "$1" ${@:2};
    fi
}

mk::exit() {
    cd $OLDWD
    exit $1
}

mk::center() {
    local _separator=$(printf '=%.0s' {1..80} | sed s/[=]/$2/g)
    echo "${_separator:0:$((39-${#1}/2))} $1 ${_separator:0:$((39-${#1}/2))}"
}




