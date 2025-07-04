#!/bin/bash

# Installs docs autogeneration tool [poxy](https://github.com/marzer/poxy).
#
# Example:
#   ./prepare-poxy.sh

# COMMON {{{

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

# }}}

mk::help() {
  echo "Installs docs autogeneration tool [poxy](https://github.com/marzer/poxy)."
  echo ""
  echo "Usage:"
  echo ""
  echo "  ./prepare-poxy.sh [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help                        = show this help"
  echo "  -v, --verbose                     = enable verbose mode (default is off)"
  echo "  --prefix <path/to/build>          = specify path to a build folder (default is current working directory)"
  echo ""
  echo "Examples:"
  echo ""
  echo "  ./prepare-poxy.sh"
  echo ""

  exit 0
}

mk::main() {
  mk::parse_args $@

  mk::info "Installing $(mk::title Poxy):\n"

  poxy --version
  if [[ $? -eq 0 ]]; then
    mk::warn "Already installed.\n"
    mk::exit 0
  fi

  _uname=$(uname)
  if [[ "$_uname" == "Linux" ]]; then
    mk::step " * check $(mk::title dvisvgm):\n"

    dvisvgm --version
    if [[ $? -ne 0 ]]; then
      sudo apt install dvisvgm
      mk::check_stage "check dvisvgm"
    fi
  fi

  pip install poxy
  mk::check_stage "install"

  poxy --version
  mk::check_stage "check poxy"

  mk::exit 0
}

mk::main $@

