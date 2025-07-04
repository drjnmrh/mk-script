#!/bin/bash

# Downloads, builds and installs docs autogeneration tool [Doxygen](https://www.doxygen.nl/).
#
# Example:
#   ./prepare-doxygen.sh --doxygen 1.14.0

# COMMON {{{

PREFIX=${PWD}
DOXYGEN_VERSION="1.14.0"

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
  --doxygen) DOXYGEN_VERSION=$2; shift;;
  *) echo "Unknown parameter passed: $1" >&2; exit 1;;
  esac; shift; done

  mk::debug "VERBOSE mode is ON\n"
  mk::debug "PREFIX is ${PREFIX}\n"
}

# }}}

mk::help() {
  echo "Downloads, builds and installs docs autogeneration tool [Doxygen](https://www.doxygen.nl/)."
  echo ""
  echo "Usage:"
  echo ""
  echo "  ./prepare-doxygen.sh [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help                        = show this help"
  echo "  -v, --verbose                     = enable verbose mode (default is off)"
  echo "  --prefix <path/to/build>          = specify path to a build folder (default is current working directory)"
  echo "  --doxygen <doxygen version>       = specify which Doxygen version to install (default is 1.14.0)"
  echo ""
  echo "Examples:"
  echo ""
  echo "  ./prepare-doxygen.sh --doxygen 1.14.0"
  echo ""

  exit 0
}

mk::main() {
  mk::parse_args $@

  mk::info "Installing $(mk::title Doxygen) v$(mk::bright ${DOXYGEN_VERSION}):\n"

  mk::step " * check $(mk::title flex):\n"

  flex --version
  if [[ $? -ne 0 ]]; then
    sudo apt-get install flex
    mk::check_stage "check flex"
  fi

  mk::step " * check $(mk::title bison):\n"

  bison --version
  if [[ $? -ne 0 ]]; then
    sudo apt-get install bison
    mk::check_stage "check bison"
  fi

  mk::mkdir_if_needed ${PREFIX}/downloaded

  cd "${PREFIX}/downloaded"

  if [[ ! -z "doxygen-${DOXYGEN_VERSION}.src.tar.gz" ]]; then
    mk::info " * Downloading sources *\n"
    curl -O https://www.doxygen.nl/files/doxygen-${DOXYGEN_VERSION}.src.tar.gz
    mk::check_stage "download"
  fi

  if [[ -d "doxygen-${DOXYGEN_VERSION}" ]]; then
    mk::debug "Cleaning up old unpacked folder... "
    rm -rf doxygen-${DOXYGEN_VERSION}
    if [[ $? -ne 0 ]]; then
      mk::warn "OOPS\n"
    else
      mk::debug "DONE\n"
    fi
  fi

  mk::info " * Unpacking sources *\n"
  tar -xvzf doxygen-${DOXYGEN_VERSION}.src.tar.gz
  mk::check_stage "unpack"

  cd "doxygen-${DOXYGEN_VERSION}"

  mk::info " * Make build folder... "
  mkdir build
  mk::check_stage "prepare"

  cd build

  mk::info " * Generate Makefiles *\n"
  cmake -G "Unix Makefiles" ..
  mk::check_stage "generate"

  mk::info " * Build Doxygen *\n"
  make -j 8
  mk::check_stage "build"

  mk::info " * Install Doxygen *\n"
  sudo make install
  mk::check_stage "install"

  mk::exit 0
}

mk::main $@

