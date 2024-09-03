#!/bin/bash

MYDIR="$(cd "$(dirname "$0")" && pwd)"
OLDDIR=${PWD}

mk_all::fail() { printf "\033[31m$1\033[0m" ${@:2}; }
mk_all::info() { printf "\033[34m$1\033[0m" ${@:2}; }
mk_all::warn() { printf "\033[33m$1\033[0m" ${@:2}; }
mk_all::done() { printf "\033[32m$1\033[0m" ${@:2}; }
mk_all::err()  { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2; }

mk_all::cleanup_and_exit() {
    cd $MYDIR
    if [[ $? -ne 0 ]]; then
        mk_all::err "Something has gone horribly wrong!"
        mk_all::fail "FAILED\n"
        exit 1
    fi

    if [[ -f "$MYDIR/mk" ]]; then
        rm $MYDIR/mk
        if [[ $? -ne 0 ]]; then
            mk_all::err "Failed to cleanup copy of the MK script!"
            mk_all::fail "FAILED\n"
            exit 1
        fi
    fi

    exit $1
}


mk_all::main() {

    if [[ ! "$MYDIR" == "$OLDDIR" ]]; then
        mk_all::err "Script must be run from its root folder!"
        mk_all::fail "FAILED\n"
        exit 1
    fi

    if [[ -f "$MYDIR/mk" ]]; then
        mk_all::warn "Found copy of the MK script - removing it..."
        rm $MYDIR/mk
        if [[ $? -ne 0 ]]; then
            mk_all::err "Could not compute!"
            mk_all::fail "FAILED\n"
            exit 1
        fi
        mk_all::done "DONE\n"
    fi

    if [[ ! -f "$MYDIR/../../mk" ]]; then
        mk_all::err "MK script wasn't found!"
        mk_all::fail "FAILED\n"
        exit 1
    fi

    cp $MYDIR/../../mk $MYDIR/
    if [[ $? -ne 0 ]]; then
        mk_all::err "Failed to copy the MK script!"
        mk_all::fail "FAILED\n"
        exit 1
    fi

    mk_all::info "Making for Android...\n"

    ./mk --platform android $@
    if [[ $? -ne 0 ]]; then
        mk_all::fail "FAILED\n"
        mk_all::cleanup_and_exit 1
    fi

    mk_all::done "ALL IS DONE\n"
    mk_all::cleanup_and_exit 0

}


mk_all::main $@

