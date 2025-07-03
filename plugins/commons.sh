#!/bin/bash

OLDWD=$(pwd)

MYDIR="$(cd "$(dirname "$0")" && pwd)"
OLDDIR=${PWD}

VERBOSE=0

PROPS=()
PROPS_LIST=()
declare -A PROPS_TABLE

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
  cd $OLDWD
  exit $1
}

mk::center() {
  local _separator=$(printf '=%.0s' {1..80} | sed s/[=]/$2/g)
  echo "${_separator:0:$((39-${#1}/2))} $1 ${_separator:0:$((39-${#1}/2))}"
}

mk::center_half() {
  local _separator=$(printf '=%.0s' {1..40} | sed s/[=]/$2/g)
  echo "${_separator:0:$((19-${#1}/2))} $1 ${_separator:0:$((19-${#1}/2))}"
}

mk::check_stage() {
  if [[ $? -ne 0 ]]; then
    mk::fail "FAILED ($1)\n"
    mk::exit 1
  fi
  mk::done "DONE ($1)\n"
}

mk::read_property() {
  local _line=$1
  # we regard all symbols on one line after '#' symbol as comments
  local _beforecomment=$(echo $_line | sed 's/^\(.*\)\([#].*\)$/\1/g')
  mk::debug "_beforecomment: $_beforecomment\n"
  local _propname=$(echo $_beforecomment | sed 's/^\(\([a-zA-Z0-9.][a-zA-Z0-9.]*[=]\)\(.*\)\)$/\2/g')
  if [[ ! "$_propname" == "" ]]; then
    _propname=${_propname:0:${#_propname}-1} # remove '=' character
    local _varname=$(echo $_propname | sed 's/[.]/_/g' | tr a-z A-Z)

    mk::debug "key $_propname ($_varname) "

    local _is_string=$(echo $_beforecomment | grep -Eo ^.*[=][\"].*[\"].*$)
    local _is_array=$(echo $_beforecomment | grep -Eo ^.*[=][\[].*[\]].*$)
    local _propvalue=""
    if [[ -n "$_is_string" ]]; then
      mk::debug "is STRING\n"
      _propvalue=$(echo $_beforecomment | sed 's/^\(.*[=]["]\(.*\)["]\)$/\2/g')
      export $_varname="$_propvalue"
      PROPS_TABLE["$_propname"]="$_propvalue"
    elif [[ -n "$_is_array" ]]; then
      mk::debug "is ARRAY\n"
      _propvalue=$(echo $_beforecomment | sed 's/^\(.*[=][[]\(.*\)[]]\)$/\2/g')
      IFS=' ' read -r -a _propvalue <<< "$_propvalue"
      export $_varname="${_propvalue[*]}"
      PROPS_TABLE["$_propname"]="${_propvalue[*]}"
    else
      mk::debug "is CUSTOM\n"
      _propvalue=$(echo $_beforecomment | sed 's/^\(.*[=]\(.*\)\)$/\2/g')
      export $_varname="$_propvalue"
      PROPS_TABLE["$_propname"]="$_propvalue"
    fi

    mk::debug "$_varname == $_propvalue\n"

    PROPS+=("-D$_varname=$_propvalue")
    PROPS_LIST+=("$_propname")
  fi
}

mk::read_local_properties() {
  PROPS=()
  PROPS_LIST=()

  local _props_file_path=$1
  mk::debug "_props_file_path == $_props_file_path\n"

  if [[ ! -e $_props_file_path ]]; then
    mk::err "No such file: $_props_file_path"
    return 1
  fi

  local _content=$(cat $_props_file_path)

  local _title=$(mk::center $_props_file_path =)
  mk::debug "$_title"
  mk::debug "\n$_content\n"
  mk::debug "$(mk::center "end" =)\n"

  IFS=$'\n'
  for line in $_content; do
    mk::read_property $line
  done

  return 0
}

