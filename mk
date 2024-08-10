#!/bin/bash

# CHANGELOG
#
# v1.0.2
# - Add version-short flag
# - Add version output after self-update
#
# v1.0.1
# - Add beautiful version printing flag
# - Add self-update flag
#
# v1.0.0
# - Implement basic functionality: generate using cmake, build, test

VERSION="1.0.2"

PLATFORM="auto"
OLDWD=$(pwd)

MYDIR="$(cd "$(dirname "$0")" && pwd)"
OLDDIR=${PWD}

PROPERTIESFILE="local.properties"

ROOT="${MYDIR}"

VERBOSE=0

JOBS=$(getconf _NPROCESSORS_ONLN)


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

PROPS=""

mk::read_local_properties() {

    local _root=$1

    if [[ ! -e $_root/${PROPERTIESFILE} ]]; then
        mk::warn "$_root doesn't contain properties file - skipping\n"
        return 1
    fi

    local _content=$(cat $_root/${PROPERTIESFILE})

    local _title=$(mk::center ${PROPERTIESFILE} =)
    mk::debug "$_title"
    mk::debug "\n$_content\n"
    mk::debug "=%.0s" {1..80}
    mk::debug "\n"

    while IFS= read -r line
    do
        # we regard all symbols on one line after '#' symbol as comments
        local _beforecomment=$(echo $line | sed 's/\(.*\)\([#].*\)$/\1/g')
        local _propname=$(echo $_beforecomment | sed 's/^\(\([a-zA-Z0-9.][a-zA-Z0-9.]*[=]\)\(.*\)\)$/\2/g')
        if [[ ! "$_propname" == "" ]]; then
            _propname=${_propname:0:${#_propname}-1} # remove '=' character
            local _propvalue=$(echo $_beforecomment | sed 's/^\(.*[=]["]\(.*\)["]\)$/\2/g')

            local _varname=$(echo $_propname | sed 's/[.]/_/g' | tr a-z A-Z)

            export $_varname="$_propvalue"
            mk::debug "$_varname == $_propvalue ($_beforecomment)\n"

            PROPS="$PROPS -D$_varname=$_propvalue"
        fi
    done < $_root/${PROPERTIESFILE}

    return 0
}


mk::help() {
    echo "Usage:"
    echo ""
    echo "  ./mk [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help                       = show this help"
    echo "  -v, --verbose                    = enable verbose mode (default is off)"
    echo "  --platform <target-platform>     = specify target platform (msvc, macosx, linux, iphone, android, emsdk)"
    echo "  --cleanup                        = perform project cleanup"
    echo "  --test                           = perform testing (performs build if needed)"
    echo "  --only <target-name>             = perform testing for the selected build target"
    echo "  --build-type <type>              = set build type: Release(default), Debug, RelWithDebInfo, MinSizeRel"
    echo "  --update-self                    = update this mk script and exit"
    echo "  --version                        = show version and exit"
    echo "  --version-short                  = show only version text and exit"
    echo ""
    echo "Examples:"
    echo ""
    echo "  ./mk --platform iphone"
    echo ""

    exit 0
}


DOCLEANUP=0
DOTESTING=0
ONLY=""
BUILD_TYPE="Release"
DOUPDATE=0
DOVERSION=0
DOSHORTVERSION=0


mk::parse_args() {

    local _defaultPrefix=0
    local _defaultBuildType=0

    # prefix dir might be changed by the local.properties
    if [[ "$PREFIX" == "${ROOT}/.output" ]]; then
        mk::debug "default prefix is $PREFIX\n"
        _defaultPrefix=1
    fi

    if [[ "$BUILD_TYPE" == "Release" ]]; then
        mk::debug "default build type is $BUILD_TYPE\n"
        _defaultBuildType=1
    fi

    while [[ "$#" > 0 ]]; do case $1 in
    -h|--help) mk::help;;
    -v|--verbose) VERBOSE=1;;
    --platform) PLATFORM=$2; shift;;
    --only) ONLY=$2; shift;;
    --cleanup) DOCLEANUP=1;;
    --test) DOTESTING=1;;
    --prefix) PREFIX=$2; _defaultPrefix=0; shift;;
    --build-type) BUILD_TYPE=$2; _defaultBuildType=0; shift;;
    --update-self) DOUPDATE=1;;
    --version) DOVERSION=1;;
    --version-short) DOSHORTVERSION=1;;
    *) echo "Unknown parameter passed: $1" >&2; exit 1;;
    esac; shift; done

    if [[ $VERBOSE -eq 1 ]]; then
        mk::debug "VERBOSE mode is ON\n"
    fi

    if [[ $_defaultPrefix -eq 1 ]]; then
        # reset prefix to the default value since root folder might be changed
        PREFIX=$ROOT/.output
    fi

    if [[ ! "${PREFIX:0:1}" == "/" ]]; then
        PREFIX="${ROOT}/${PREFIX}"
    fi

    if [[ $_defaultBuildType -eq 1 ]]; then
        BUILD_TYPE=Release
    fi
}


mk::main() {

    mk::parse_args $@

    if [[ $DOSHORTVERSION -eq 1 ]]; then
        VERBOSE=1
        mk::debug "$VERSION\n"
        mk::exit 0
    fi

    if [[ $DOVERSION -eq 1 ]]; then
        VERBOSE=1
        mk::debug "Stoned Fox's "
        mk::fail "Awesome "
        mk::done "MK"
        mk::debug " Script "
        mk::done "v$VERSION\n"
        mk::debug "MIT License\n"
        mk::info "https://github.com/drjnmrh/mk-script.git\n"
        mk::exit 0
    fi

    if [[ $DOUPDATE -eq 1 ]]; then
        mk::info "Update self... \n"
        curl -LO https://raw.githubusercontent.com/drjnmrh/mk-script/main/mk
        if [[ $? -ne 0 ]]; then
            mk::fail "FAILED(Update)\n"
            mk::exit 1
        fi
        _version=$($MYDIR/mk --version-short)
        mk::info "Updated to v$_version\n"
        mk::done "DONE\n"
        mk::exit 0
    fi

    mk::read_local_properties ${ROOT}

    if [[ "$PLATFORM" == "auto" ]]; then
        _uname=$(uname)
        if [[ "$_uname" == "Darwin" ]]; then
            PLATFORM=macosx
        elif [[ "$_uname" == "Linux" ]]; then
            PLATFORM=linux
        fi
    fi

    _builddir="build-${PLATFORM}"

    if [[ $DOCLEANUP -eq 1 ]]; then
        mk::info "Cleanup: "
        if [[ -d "$_builddir" ]]; then
            rm -rf "$_builddir"
            if [[ $? -ne 0 ]]; then
                mk::fail "FAILED(Cleanup)\n"
                mk::exit 1
            else
                mk::done "DONE\n"
            fi
        else
            mk::warn "No need to cleanup\n"
        fi
    fi
    if [[ ! -d "$_builddir" ]]; then
        mkdir "$_builddir"
    fi

    if [[ $VERBOSE -eq 1 ]]; then
        VERBOSE_FLAG="--debug-find"
    fi

    cd "$_builddir"

    cmakeToolchainFile=""
    if [[ "$PLATFORM" == "mingw" ]]; then
        cmakeToolchainFile="-DCMAKE_TOOLCHAIN_FILE=../scripts/MinGW64-toolchain.cmake"
    fi

    BUILD_TYPE=$(echo $BUILD_TYPE | tr '[:lower:]' '[:upper:]')
    if [[ "$BUILD_TYPE" == "RELEASE" ]]; then
        BUILD_TYPE="Release"
    elif [[ "$BUILD_TYPE" == "DEBUG" ]]; then
        BUILD_TYPE="Debug"
    elif [[ "$BUILD_TYPE" == "MINSIZEREL" ]]; then
        BUILD_TYPE="MinSizeRel"
    elif [[ "$BUILD_TYPE" == "RELWITHDEBINFO" ]]; then
        BUILD_TYPE="RelWithDebInfo"
    else
        mk::err "Unknown build type $BUILD_TYPE\n"
        mk::fail "FAILED(Prepare)\n"
        mk::exit 1
    fi

    cmake ../sources $VERBOSE_FLAG -DVERBOSE=$VERBOSE $PROPS -DCMAKE_BUILD_TYPE=$BUILD_TYPE $cmakeToolchainFile
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(Generate)\n"
        mk::exit 1
    fi

    make -j ${JOBS}
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(Build)\n"
        mk::exit 1
    fi

    if [[ $DOTESTING -eq 1 ]]; then
        if [[ $ONLY == "" ]]; then
            ctest --verbose --timeout 300
        else
            tmp=${ONLY//"::"/$'\2'}
            IFS=$'\2' read -a arr <<< "$tmp"
            ONLY=${arr[0]}
            TEST=${arr[1]}
            TEST_ARGUMENTS=$TEST ctest --verbose --timeout 300 -R $ONLY
        fi
        if [[ $? -ne 0 ]]; then
            mk::fail "FAILED(Test)\n"
            mk::exit 1
        fi
    fi
    cd $OLDWD
}

mk::main $@
