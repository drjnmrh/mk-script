#!/bin/bash

# Downloads, builds and installs [gRPC](https://github.com/grpc/grpc)
# for Linux and Wine-MSVC host platforms.
#
# Example:
#   ./prepare-grpc.sh --prefix ~/src/3rdparty

# COMMON {{{1

PREFIX=${PWD}

MYDIR="$(cd "$(dirname "$0")" && pwd)"
OLDDIR=${PWD}
VERBOSE=0

CURRENT_COLOR="\033[0m"

mk::colored() {
  local _color=$1
  local _text="$2"

  local _old_color="$CURRENT_COLOR"
  CURRENT_COLOR="\033[${_color}m"

  _text=$(echo "$_text" | sed "s/\[0m/\[${_color}m/g")

  echo "${CURRENT_COLOR}${_text}${_old_color}"
  CURRENT_COLOR="$_old_color"
}

mk::fail() {
  local _txt=$(mk::colored 31 "$1")
  printf "$_txt" ${@:2};
}

mk::info() {
  local _txt=$(mk::colored 34 "$1")
  printf "$_txt" ${@:2};
}

mk::warn() {
  local _txt=$(mk::colored 33 "$1")
  printf "$_txt" ${@:2};
}

mk::done() {
  local _txt=$(mk::colored 32 "$1")
  printf "$_txt" ${@:2};
}

mk::step() {
  local _txt=$(mk::colored 37 "$1")
  printf "$_txt" ${@:2};
}

mk::title() {
  local _txt=$(mk::colored 32 "$1")
  echo "$_txt"
}

mk::bright() {
  local _txt=$(mk::colored 33 "$1")
  echo "$_txt"
}

mk::plane() {
  local _txt=$(mk::colored 37 "$1")
  echo "$_txt"
}

mk::err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2;
}

mk::debug() {
  if [[ $VERBOSE -eq 1 ]]; then
    printf "# $1" ${@:2};
  fi
}

mk::exit() {
  cd $OLDDIR
  if [[ $? -ne 0 ]]; then
    mk::err "Something has gone horribly wrong!"
    mk::fail "FAILED\n"
    exit 1
  fi

  exit $1
}

mk::check_stage() {
    if [[ $? -ne 0 ]]; then
        mk::fail "FAILED($1)\n"
        mk::exit 1
    fi
    mk::done "DONE($1)\n"
}

mk::mkdir_if_needed() {
  if [[ ! -d "$1" ]]; then
    mk::debug "creating folder $1... "
    mkdir -p "$1"
    mk::check_stage "prepare"
  fi
}

mk::parse_args() {
  while [[ "$#" > 0 ]]; do case $1 in
  -h|--help) mk::help;;
  -v|--verbose) VERBOSE=1;;
  --prefix) PREFIX=$2; _defaultPrefix=0; shift;;
  *) echo "Unknown parameter passed: $1" >&2; exit 1;;
  esac; shift; done

  mk::debug "VERBOSE mode is ON\n"
  mk::debug "PREFIX is ${PREFIX}\n"
}

# }}}1

mk::help() {
  echo "Downloads, builds and installs [gRPC](https://github.com/grpc/grpc)"
  echo "for Linux and Wine-MSVC host platforms."
  echo ""
  echo "Usage:"
  echo ""
  echo "  ./prepare-grpc.sh [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help                        = show this help"
  echo "  -v, --verbose                     = enable verbose mode (default is off)"
  echo "  --prefix <path/to/build>          = specify path to a build folder (default is CWD)"
  echo ""
  echo "Examples:"
  echo ""
  echo "  ./prepare-grpc.sh"
  echo ""

  exit 0
}

mk::main() {
  mk::parse_args $@

  mk::mkdir_if_needed $PREFIX
  mk::mkdir_if_needed $PREFIX/downloaded

  cd $PREFIX/downloaded

  if [[ ! -d "$PREFIX/downloaded/grpc" ]]; then
    mk::info "Cloning $(mk::title gRPC) repo...\n"

    git clone --recurse-submodules -b v1.66.0 --depth 1 --shallow-submodules https://github.com/grpc/grpc
    mk::check_stage "download"
  fi

  cd grpc

  if [[ -d "cmake/build" ]]; then
    mk::step "Clean CMake build folder...\n"
    rm -rf cmake/build
    if [[ $? -ne 0 ]]; then
      mk::warn "FAILED(clean)\n"
    else
      mk::done "DONE(clean)\n"
    fi
  fi

# LINUX {{{

  mkdir -p cmake/build
  pushd cmake/build

  if [[ -e "$PREFIX/linux/bin/grpc_cpp_plugin" ]]; then
    mk::info "$(mk::title gRPC) for $(mk::bright Linux) Host is already installed - $(mk::plane skipping).\n"
  else
    mk::info "Running $(mk::bright CMake) for $(mk::title gRPC) ($(mk::bright Linux) Host)...\n"

    cmake ../.. -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_CXX_STANDARD=17 -DCMAKE_INSTALL_PREFIX=$PREFIX/linux
    mk::check_stage "linux-cmake"

    mk::info "Building $(mk::title gRPC) ($(mk::bright Linux) Host)...\n"

    make -j 4
    mk::check_stage "linux-build"

    make install
    mk::check_stage "linux-install"
  fi

  popd

  mk::step "Cleanup build folder ($(mk::bright Linux) Host)... "
  rm -rf cmake/build
  mk::check_stage "linux-cleanup"

# }}}

# WINE-MSVC {{{

  mkdir -p cmake/build
  pushd cmake/build

  if [[ -e "$PREFIX/msvc/bin/grpc_cpp_plugin.exe" ]]; then
    mk::info "$(mk::title gRPC) for $(mk::bright Wine-MSVC) is already installed - $(mk::plane skipping).\n"
  else
    mk::info "Running $(mk::bright CMake) for $(mk::title gRPC) ($(mk::bright Wine-MSVC))...\n"

    export PATH=~/my-msvc/opt/msvc/bin/x64:$PREFIX/linux/bin:$PATH

    CC=cl CXX=cl cmake ../.. -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_CXX_STANDARD=17 -DCMAKE_INSTALL_PREFIX=$PREFIX/msvc -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=Windows -DOPENSSL_NO_ASM=ON
    mk::check_stage "msvc-cmake"

    mk::info "Building $(mk::title gRPC) ($(mk::bright Wine-MSVC))...\n"

    cmake --build . --parallel 4 --config Release
    mk::check_stage "msvc-build"

    mk::info "Installing $(mk::title gRPC) ($(mk::bright Wine-MSVC))...\n"

    make install
    mk::check_stage "msvc-install"
  fi

  popd

  mk::step "Cleanup build folder ($(mk::bright Wine-MSVC) Host)... "
  rm -rf cmake/build
  mk::check_stage "msvc-cleanup"

# }}}

  mk::exit 0
}

mk::main $@

