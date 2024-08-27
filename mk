#!/bin/bash

# CHANGELOG
#
# v1.0.6
# - Fix local.properties parsing for Msys (VSCode git bash environment)
# - Fix MSVC build command
#
# v1.0.5
# - Add --tocmake flag which allows to pass user-defined CMake variables to the cmake command
# - Add Xcode project generation for macosx and iphone platforms
# - Fix toolchain option handling in case of an absolute path
#
# v1.0.4
# - Add toolchain option which allows to set path to the CMake toolchain file
#
# v1.0.3
# - Add source flag which allows to set the path to the main CMakeLists.txt script
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

VERSION="1.0.6"

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
    mk::debug "_root == $_root\n"

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

    _uname=$(uname -o)

    if [[ "$_uname" == "Msys" ]]; then
        IFS=$'\n'
        for line in $_content; do
            # we regard all symbols on one line after '#' symbol as comments
            local _beforecomment=$(echo $line | sed 's/\(.*\)\([#].*\)$/\1/g')
            local _propname=$(echo $_beforecomment | sed 's/^\(\([a-zA-Z0-9.][a-zA-Z0-9.]*[=]\)\(.*\)\)$/\2/g')
            if [[ ! "$_propname" == "" ]]; then
                _propname=${_propname:0:${#_propname}-1} # remove '=' character
                local _propvalue=$(echo $_beforecomment | sed 's/^\(.*[=]["]\(.*\)["]\)$/\2/g')

                local _varname=$(echo $_propname | sed 's/[.]/_/g' | tr a-z A-Z)

                export $_varname="$_propvalue"
                mk::debug "$_varname == $_propvalue ($_beforecomment)\n"

                PROPS="${PROPS[@]} -D$_varname=$_propvalue"
            fi
        done
    else
        while IFS= read -r line; do
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
    fi

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
    echo "  --source <path/to/script>        = specify path to the main CMakeLists.txt script (default: $MYDIR/sources)"
    echo "  --toolchain <path/to/toolchain>  = specify path to the CMake toolchain file"
    echo "  --tocmake <CMake flag>           = specify CMake flag to be passed to the generator (e.g. -DIOS_TYPE=iphone)"
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
DEFAULT_SOURCE_PATH="$MYDIR/sources"
SOURCE_PATH="$DEFAULT_SOURCE_PATH"
TOOLCHAIN="null"
TOCMAKE=""


mk::parse_args() {

    local _defaultPrefix=0
    local _defaultBuildType=0
    local _defaultSourcePath=0

    # prefix dir might be changed by the local.properties
    if [[ "$PREFIX" == "${ROOT}/.output" ]]; then
        mk::debug "default prefix is $PREFIX\n"
        _defaultPrefix=1
    fi

    if [[ "$BUILD_TYPE" == "Release" ]]; then
        mk::debug "default build type is $BUILD_TYPE\n"
        _defaultBuildType=1
    fi

    if [[ "$SOURCE_PATH" == "$DEFAULT_SOURCE_PATH" ]]; then
        mk::debug "default source path is $SOURCE_PATH\n"
        _defaultSourcePath=1
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
    --source) SOURCE_PATH=$2; _defaultSourcePath=0; shift;;
    --toolchain) TOOLCHAIN=$2; shift;;
    --tocmake) TOCMAKE="$TOCMAKE $2"; shift;;
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

    if [[ $_defaultSourcePath -eq 1 ]]; then
        SOURCE_PATH="$DEFAULT_SOURCE_PATH"
    fi
}


mk::print_version_and_exit() {
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
}


mk::update_self_and_exit() {
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
}


mk::normalize_build_type() {
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
}


mk::normalize_source_path() {
    case $SOURCE_PATH in
        /*) mk::debug "Source path is absolute\n";;
        *) SOURCE_PATH="$OLDWD/$SOURCE_PATH";;
    esac
    mk::debug "SOURCE_PATH=$SOURCE_PATH\n"
}


mk::construct_toolchain_flag() {
    if [[ "$TOOLCHAIN" == "null" ]]; then
        echo ""
    else
        case $TOOLCHAIN in
            /*) ;;
            *) TOOLCHAIN="$OLDWD/$TOOLCHAIN";;
        esac

        if [[ ! -f "$TOOLCHAIN" ]]; then
            mk::err "Toolchain file $TOOLCHAIN doesn't exist!\n"
            mk::fail "FAILED(Prepare)\n"
            mk::exit 1
        fi

        echo "-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN"
    fi
}


mk::main() {

    mk::parse_args $@
    mk::print_version_and_exit
    mk::update_self_and_exit
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

    mk::normalize_build_type
    mk::normalize_source_path

    _toolchainFlag=$(mk::construct_toolchain_flag)

    _generator=""
    _cmakeBuildType=" -DCMAKE_BUILD_TYPE=$BUILD_TYPE"
    _cmakeBuildConfigType=""
    _ctestConfigType=" -C $BUILD_TYPE"
    _buildExtraFlags=""

    if [[ "$PLATFORM" == "macosx" || "$PLATFORM" == "iphone" ]]; then
        _generator="-G Xcode"
        _cmakeBuildType=""
        _cmakeBuildConfigType="--config Release"
        _ctestConfigType=" -C Release"
        _buildExtraFlags=" -- -quiet"
    elif [[ "$PLATFORM" == "msvc" ]]; then
        _generator="" # it seems that CMake automatically sets VSCode generator
        _cmakeBuildType=""
        _cmakeBuildConfigType="--config $BUILD_TYPE"
        _ctestConfigType=" -C $BUILD_TYPE"
        _buildExtraFlags=""
    fi

    mk::debug "Flags for CMake:-DVERBOSE=$VERBOSE${PROPS[@]}${TOCMAKE[@]}$_cmakeBuildType} $SOURCE_PATH $_generator $VERBOSE_FLAG $_toolchainFlag;\n"

    _uname=$(uname -o)
    if [[ "$_uname" == "Msys" ]]; then
        eval cmake -DVERBOSE=$VERBOSE${PROPS[@]}${TOCMAKE[@]}$_cmakeBuildType $SOURCE_PATH $_generator $VERBOSE_FLAG $_toolchainFlag
    else
        cmake -DVERBOSE=$VERBOSE${PROPS[@]}${TOCMAKE[@]}$_cmakeBuildType $SOURCE_PATH $_generator $VERBOSE_FLAG $_toolchainFlag
    fi
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(Generate)\n"
        mk::exit 1
    fi

    cmake --build . $_cmakeBuildConfigType --parallel ${JOBS}${_buildExtraFlags[@]}
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(Build)\n"
        mk::exit 1
    fi

    if [[ $DOTESTING -eq 1 ]]; then
        if [[ $ONLY == "" ]]; then
            ctest --verbose --timeout 300${_ctestConfigType[@]}
        else
            tmp=${ONLY//"::"/$'\2'}
            IFS=$'\2' read -a arr <<< "$tmp"
            ONLY=${arr[0]}
            TEST=${arr[1]}
            TEST_ARGUMENTS=$TEST ctest --verbose --timeout 300${_ctestConfigType[@]} -R $ONLY
        fi
        if [[ $? -ne 0 ]]; then
            mk::fail "FAILED(Test)\n"
            mk::exit 1
        fi
    fi
    cd $OLDWD
}

mk::main $@
