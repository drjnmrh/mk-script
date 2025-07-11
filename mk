#!/bin/bash

# CHANGELOG
#
# v1.1.1
# - Add ```--to-ctest``` param to pass flags to _ctest_ tool.
#
# v1.1.0
# - Change how parameters are passed to plugins.
# - Renamed --tocmake and --nobuild flags to --to-cmake and --no-build correspondingly.
#
# v1.0.13
# - Enhance coloring functions.
# - Introduce arrays and non-quoted values to the properties parser.
#
# v1.0.12
# - Add ```mk::check_stage``` functions to commons.sh.
#
# v1.0.11
# - Add ```--properties``` flag which allows to specify path to the ```local.properties``` file.
#
# v1.0.10
# - Add plugins subsystem
# - Add git-branch-cleanup plugin
#
# v1.0.9
# - Add 'nobuild' flag
#
# v1.0.8
# - Add Android platform support
# - Refactor PROPS list
#
# v1.0.7
# - Fix build type, build and ctest config flags setup
# - Refactor platform-specific branches: localized to one place
# - Add MSVC platform autodetect branch
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

VERSION="1.1.1"

PLATFORM="auto"
OLDWD=$(pwd)

MYDIR="$(cd "$(dirname "$0")" && pwd)"
OLDDIR=${PWD}

PROPERTIESFILE="local.properties"

ROOT="${MYDIR}"

VERBOSE=0

JOBS=$(getconf _NPROCESSORS_ONLN)


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

mk::cool() {
  local _txt=$(mk::colored 31 "$1")
  echo "$_txt"
}

mk::err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2;
}

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

PROPS=()
PROPS_LIST=()
declare -A PROPS_TABLE
GRADLEW_PROPS=()

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

    mk::debug "$_varname == $_propvalue;\n"

    PROPS+=("-D$_varname=$_propvalue")
    PROPS_LIST+=("$_propname")

    _lowercase=$(echo $_varname | tr A-Z a-z)
    GRADLEW_PROPS+=("-P$_lowercase=$_propvalue")
  fi
}

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
  mk::debug "$(mk::center "end" =)\n"

  local _old_ifs=$IFS
  IFS=$'\n'
  for line in $_content; do
    mk::read_property $line
  done
  IFS=$_old_ifs

  return 0
}


mk::help() {
  echo "Usage:"
  echo ""
  echo "  ./mk [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help                        = show this help"
  echo "  -v, --verbose                     = enable verbose mode (default is off)"
  echo "  --platform <target-platform>      = specify target platform (msvc, macosx, linux, iphone, android, emsdk)"
  echo "  --cleanup                         = perform project cleanup"
  echo "  --test                            = perform testing (performs build if needed)"
  echo "  --only <target-name>              = perform testing for the selected build target"
  echo "  --build-type <type>               = set build type: Release(default), Debug, RelWithDebInfo, MinSizeRel"
  echo "  --update-self                     = update this mk script and exit"
  echo "  --version                         = show version and exit"
  echo "  --version-short                   = show only version text and exit"
  echo "  --source <path/to/script>         = specify path to the main CMakeLists.txt script (default: $MYDIR/sources)"
  echo "  --toolchain <path/to/toolchain>   = specify path to the CMake toolchain file"
  echo "  --to-cmake <CMake flag>           = specify CMake flag to be passed to the generator (e.g. -DIOS_TYPE=iphone)"
  echo "  --to-ctest <CTest flag>           = add a CTest flag to the flags, passed to the tool (e.g. --progress)"
  echo "  --no-build                        = skip build step"
  echo "  --plugin <plugin-name>            = run specific plugin"
  echo "  --properties <path/to/properties> = specify path to local.properties file (default: ${PWD})."
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
DEFAULT_PROPERTIES_PATH="${ROOT}"
PROPERTIES_PATH="$DEFAULT_PROPERTIES_PATH"
SOURCE_PATH="$DEFAULT_SOURCE_PATH"
TOOLCHAIN="null"
TOCMAKE=""
TOCTEST=()
ANDROIDABI=(armeabi-v7a arm64-v8a x86_64)
NOBUILD=0
PLUGIN=""

PLUGIN_ARGS=()

mk::parse_args() {
  local _defaultPrefix=0
  local _defaultBuildType=0
  local _defaultSourcePath=0
  local _defaultPropertiesPath=0

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

  if [[ "$PROPERTIES_PATH" == "$DEFAULT_PROPERTIES_PATH" ]]; then
    mk::debug "default local.properties path is $PROPERTIES_PATH\n"
    _defaultPropertiesPath=1
  fi

  while [[ "$#" > 0 ]]; do case $1 in
    -h|--help) mk::help; PLUGIN_ARGS+=("--help");;
    -v|--verbose) VERBOSE=1; PLUGIN_ARGS+=("--verbose");;
    --platform) PLATFORM=$2; PLUGIN_ARGS+=("--platform"); PLUGIN_ARGS+=("$2"); shift;;
    --only) ONLY=$2; PLUGIN_ARGS+=("--only"); PLUGIN_ARGS+=("$2"); shift;;
    --cleanup) DOCLEANUP=1; PLUGIN_ARGS+=("--cleanup");;
    --test) DOTESTING=1; PLUGIN_ARGS+=("--test");;
    --prefix) PREFIX=$2; _defaultPrefix=0; PLUGIN_ARGS+=("--prefix"); PLUGIN_ARGS+=("$2"); shift;;
    --build-type) BUILD_TYPE=$2; _defaultBuildType=0; PLUGIN_ARGS+=("--build-type"); PLUGIN_ARGS+=("$2"); shift;;
    --update-self) DOUPDATE=1;;
    --version) DOVERSION=1;;
    --version-short) DOSHORTVERSION=1;;
    --source) SOURCE_PATH=$2; _defaultSourcePath=0; PLUGIN_ARGS+=("--source"); PLUGIN_ARGS+=("$2"); shift;;
    --toolchain) TOOLCHAIN=$2; PLUGIN_ARGS+=("--toolchain"); PLUGIN_ARGS+=("$2"); shift;;
    --to-cmake) TOCMAKE="$TOCMAKE $2"; PLUGIN_ARGS+=("--to-cmake"); PLUGIN_ARGS+=("$2"); shift;;
    --to-ctest) TOCTEST+=("$2"); PLUGIN_ARGS+=("--to-ctest"); PLUGIN_ARGS+=("$2"); shift;;
    --no-build) NOBUILD=1; PLUGIN_ARGS+=("--no-build");;
    --plugin) PLUGIN=$2; shift;;
    --properties) PROPERTIES_PATH=$2; _defaultPropertiesPath=0; PLUGIN_ARGS+=("--properties"); PLUGIN_ARGS+=("$2"); shift;;
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

  if [[ $_defaultPropertiesPath -eq 1 ]]; then
    PROPERTIES_PATH="$DEFAULT_PROPERTIES_PATH"
  fi
}


mk::print_version_and_exit() {
  if [[ $DOSHORTVERSION -eq 1 ]]; then
    printf "$VERSION\n"
    mk::exit 0
  fi

  if [[ $DOVERSION -eq 1 ]]; then
    mk::step "Stoned Fox's $(mk::cool Awesome) $(mk::title MK) Script $(mk::title v$VERSION)\n"
    mk::step "MIT License\n"
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


DOWNLOADED_PLUGINS_PATH="$MYDIR/.mk-plugins"


mk::fetch_plugins_script() {
  _script=$1

  if [[ ! -d "$DOWNLOADED_PLUGINS_PATH" ]]; then
    mk::debug "Create downloaded plugins path... "
    mkdir -p $DOWNLOADED_PLUGINS_PATH
    if [[ $? -ne 0 ]]; then
      mk::fail "FAILED(Create plugins folder)\n"
      mk::exit 1
    fi
    mk::debug "DONE(Create plugins folder)\n"
  fi

  if [[ ! -e "$DOWNLOADED_PLUGINS_PATH/$1" ]]; then
    if [[ -e "$MYDIR/plugins/$1" ]]; then
      mk::info "Copying plugin file \033[33m$1\033[34m... "
      cp $MYDIR/plugins/$1 $DOWNLOADED_PLUGINS_PATH/
      if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(Copy $1)\n"
        mk::exit 1
      fi
      mk::done "DONE(Copy $1)\n"
    else
      mk::info "Downloading \033[33m$1\033[34m plugin...\n"
      _olddir=$(pwd)
      cd $DOWNLOADED_PLUGINS_PATH

      curl -OL https://raw.githubusercontent.com/drjnmrh/mk-script/main/plugins/$1
      if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(Download $1)\n"
        mk::exit 1
      fi
      mk::done "DONE(Download $1)\n"
      cd $_olddir
    fi
  fi
}

mk::try_run_plugin() {
  if [[ ! -z "$PLUGIN" ]]; then
    if [[ $DOCLEANUP -eq 1 ]]; then
      if [[ -d "$DOWNLOADED_PLUGINS_PATH" ]]; then
        mk::info "Cleanup downloaded plugins... "
        rm -rf $DOWNLOADED_PLUGINS_PATH
        if [[ $? -ne 0 ]]; then
          mk::warn "FAILED(Plugins Cleanup)\n"
        else
          mk::done "DONE(Plugins Cleanup)\n"
        fi
      fi
    fi

    mk::fetch_plugins_script commons.sh
    mk::fetch_plugins_script $PLUGIN
    chmod +x $DOWNLOADED_PLUGINS_PATH/$PLUGIN
    if [[ $? -ne 0 ]]; then
      mk::fail "FAILED(Set permissions)\n"
      mk::exit 1
    fi

    _cmd=($DOWNLOADED_PLUGINS_PATH/$PLUGIN $(pwd) ${PLUGIN_ARGS[@]})
    "${_cmd[@]}"
    if [[ $? -ne 0 ]]; then
      mk::fail "FAILED(Run Plugin)\n"
      mk::exit 1
    fi
    mk::done "DONE(Run Plugin)\n"
    mk::exit 0
  fi
}


mk::main() {
  mk::parse_args $@
  mk::print_version_and_exit
  mk::update_self_and_exit
  mk::read_local_properties ${PROPERTIES_PATH}

  if [[ "$PLATFORM" == "auto" ]]; then
    _uname=$(uname)
    if [[ "$_uname" == "Darwin" ]]; then
      PLATFORM=macosx
    elif [[ "$_uname" == "Linux" ]]; then
      PLATFORM=linux
    elif [[ "$_uname" == MINGW64* ]]; then
      PLATFORM=msvc
    fi
  fi

  mk::try_run_plugin

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

  if [[ "$PLATFORM" == "android" ]]; then
    # First, find in sources 'gradlew' script. MK will consider folder with
    # this file an Android Project root folder.

    _gradlew=$(find $SOURCE_PATH -name "gradlew" -type f)
    if [[ ! -z "$_gradlew" ]]; then
      _gradlewPath=$(dirname $_gradlew)
      mk::info "Found Gradlew script in $_gradlewPath\n"
      cd $_gradlewPath
      _com=( ./gradlew clean assembleRelease -Pverbose=${VERBOSE} "${GRADLEW_PROPS[@]}")
      "${_com[@]}"
      if [[ $? -ne 0 ]]; then
        mk::fail "FAIL(Gradle)\n"
        mk::exit 1
      fi
    else
      mk::info "No Gradlew script in sources - trying to build using NDK cmake\n"

      if [[ -z "${ANDROID_HOME}" ]]; then
        mk::debug "ANDROID_HOME is not set - trying android.dir from local.properties\n"
        ANDROID_HOME=${ANDROID_DIR}
      fi
      if [[ -z "${ANDROID_HOME}" ]]; then
        mk::fail "Android requires ANDROID_HOME environment variable to be set\n"
        mk::exit 1
      fi

      if [[ -z "${NDK_HOME}" ]]; then
        mk::debug "NDK_HOME is not set - trying ndk.dir from local.properties\n"
        NDK_HOME=${NDK_DIR}
      fi
      if [[ -z "${NDK_HOME}" ]]; then
        mk::fail "Android requires NDK_HOME environment variable to be set\n"
        mk::exit 1
      fi
      mk::debug "ANDROID_HOME = $ANDROID_HOME\n"
      mk::debug "NDK_HOME = $NDK_HOME\n"

      _toolchain=$NDK_HOME/build/cmake/android.toolchain.cmake
      _cmaketool=$ANDROID_HOME/cmake/3.22.1/bin/cmake

      for _abi in ${ANDROIDABI[@]}; do
        if [[ ! -d "$_abi" ]]; then
          mkdir $_abi
        fi
        cd $_abi

        _prefix=$PREFIX/android/$_abi

        $_cmaketool $SOURCE_PATH -DCMAKE_TOOLCHAIN_FILE=$_toolchain \
          -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
          -DANDROID_ABI=$_abi -DCMAKE_INSTALL_PREFIX=$_prefix \
          -DANDROID_TOOLCHAIN=clang -DANDROID_STL=c++_static \
          -DANDROID_ARM_NEON=ON -DANDROID_PLATFORM=android-28 \
          -DCMAKE_MAKE_PROGRAM=$ANDROID_HOME/cmake/3.22.1/bin/ninja \
          -G "Ninja" -DVERBOSE=$VERBOSE ${PROPS[@]} ${TOCMAKE[@]} $VERBOSE_FLAG
        if [[ $? -ne 0 ]]; then
          mk::fail "FAILED(Generate $_abi)\n"
          mk::exit 1
        fi
        mk::done "DONE(CMake)\n"

        if [[ $NOBUILD -eq 0 ]]; then
          $_cmaketool --build . --config $BUILD_TYPE -- -j${JOBS}
          if [[ $? -ne 0 ]]; then
            mk::fail "FAILED(Build $_abi)\n"
            mk::exit 1
          fi
          mk::done "DONE(Build)\n"
        fi

        cd ..
      done
    fi
  else
    mk::debug "Flags for CMake:-DVERBOSE=$VERBOSE ${PROPS[*]} ${TOCMAKE[*]}${_cmakeBuildType} $SOURCE_PATH $_generator$VERBOSE_FLAG $_toolchainFlag;\n"

    eval cmake -DVERBOSE=$VERBOSE ${PROPS[@]} ${TOCMAKE[@]}$_cmakeBuildType $SOURCE_PATH $_generator $VERBOSE_FLAG $_toolchainFlag
    if [[ $? -ne 0 ]]; then
      mk::fail "FAILED(Generate)\n"
      mk::exit 1
    fi
    mk::done "DONE(CMake)\n"

    if [[ $NOBUILD -eq 0 ]]; then
      cmake --build . $_cmakeBuildConfigType --parallel ${JOBS}${_buildExtraFlags[@]}
      if [[ $? -ne 0 ]]; then
        mk::fail "FAILED(Build)\n"
        mk::exit 1
      fi
      mk::done "DONE(Build)\n"
    fi
  fi

  if [[ $DOTESTING -eq 1 ]]; then
    mk::debug "CTEST ARGS are ${TOCTEST[*]}; \n"
    if [[ $ONLY == "" ]]; then
      ctest --timeout 300${_ctestConfigType[@]} ${TOCTEST[*]}
    else
      tmp=${ONLY//"::"/$'\2'}
      IFS=$'\2' read -a arr <<< "$tmp"
      ONLY=${arr[0]}
      TEST=${arr[1]}
      TEST_ARGUMENTS=$TEST ctest --timeout 300${_ctestConfigType[@]} ${TOCTEST[*]} -R $ONLY
    fi
    if [[ $? -ne 0 ]]; then
      mk::fail "FAILED(Test)\n"
      mk::exit 1
    fi
    mk::done "DONE(Testing)\n"
  fi
  cd $OLDWD
}

mk::main $@

