#!/bin/bash
set -euox pipefail

main() {
  if [ $# -ne 1 ]; then
    cat <<EOF
Usage:
    build_otp_macos.bash ref_name
EOF
    exit 1
  fi

  local ref_name=$1
  : "${OPENSSL_VERSION:=3.1.6}"
  : "${OPENSSL_DIR:=/tmp/builds/openssl-${OPENSSL_VERSION}-macos}"
  : "${WXWIDGETS_VERSION:=3.2.6}"
  : "${WXWIDGETS_DIR:=/tmp/builds/wxwidgets-${WXWIDGETS_VERSION}-macos}"
  : "${OTP_DIR:=/tmp/builds/otp-${ref_name}-openssl-${OPENSSL_VERSION}-wxwidgets-${WXWIDGETS_VERSION}-macos}"
  export MAKEFLAGS=-j$(getconf _NPROCESSORS_ONLN)
  export CFLAGS="-Os -fno-common -mmacosx-version-min=11.0"

  build_openssl "${OPENSSL_VERSION}"
  build_wxwidgets "${WXWIDGETS_VERSION}"

  export PATH="${WXWIDGETS_DIR}/bin:$PATH"
  build_otp "${ref_name}"
}

build_openssl() {
  local version=$1
  local rel_dir="${OPENSSL_DIR}"
  local src_dir="/tmp/builds/src-openssl-${version}"

  if [ -d "${rel_dir}/bin" ]; then
    echo "${rel_dir}/bin already exists, skipping build"
    ${rel_dir}/bin/openssl version
    return
  fi

  local ref_name="openssl-${version}"
  local url="https://github.com/openssl/openssl"

  if [ ! -d ${src_dir} ]; then
    git clone --depth 1 ${url} --branch ${ref_name} ${src_dir}
  fi

  (
    cd ${src_dir}
    git clean -dfx
    ./config --prefix=${rel_dir} ${CFLAGS}
    make
    make install_sw
  )

  if ! ${rel_dir}/bin/openssl version; then
    rm -rf ${rel_dir}
  fi
}

build_wxwidgets() {
  local version=$1
  local rel_dir="${WXWIDGETS_DIR}"
  local src_dir="/tmp/builds/src-wxwidgets-${version}"

  if [ -d "${rel_dir}/bin" ]; then
    echo "${rel_dir}/bin already exists, skipping build"
    ${rel_dir}/bin/wx-config --version
    return
  fi

  if [ ! -d ${src_dir} ]; then
    curl --fail -LO https://github.com/wxWidgets/wxWidgets/releases/download/v$version/wxWidgets-$version.tar.bz2
    tar -xf wxWidgets-$version.tar.bz2
    mv wxWidgets-$version $src_dir
    rm wxWidgets-$version.tar.bz2
  fi

  (
    cd ${src_dir}
    ./configure \
      --disable-shared \
      --prefix=${rel_dir} \
      --with-cocoa \
      --with-macosx-version-min=11.0 \
      --disable-sys-libs
    make
    make install
  )

  if ! ${rel_dir}/bin/wx-config --version; then
    rm -rf ${rel_dir}
  fi
}

build_otp() {
  local ref_name="$1"
  local rel_dir="${OTP_DIR}"
  local src_dir="/tmp/builds/src-otp-${ref_name}"
  local wx_test

  local test_cmd="erl -noshell -eval 'io:format(\"~s~s~n\", [
    erlang:system_info(system_version),
    erlang:system_info(system_architecture)]),
    ok = crypto:start(), io:format(\"crypto ok~n\"),
    wx:new(), io:format(\"wx ok~n\"),
    halt().'"

  if [ -d "${rel_dir}/bin" ]; then
    echo "${rel_dir}/bin already exists, skipping build"
    eval ${rel_dir}/bin/${test_cmd}
    return
  fi

  local url="https://github.com/erlang/otp"

  if [ ! -d ${src_dir} ]; then
    git clone --depth 1 ${url} --branch ${ref_name} ${src_dir}
  fi

  (
    cd $src_dir
    git clean -dfx
    export ERL_TOP=$PWD
    export ERLC_USE_SERVER=true

    ./otp_build configure \
      --with-ssl=${OPENSSL_DIR} \
      --disable-dynamic-ssl-lib

    ./otp_build boot -a
    ./otp_build release -a ${rel_dir}
    cd ${rel_dir}
    ./Install -sasl $PWD

    # Remove Install since the release is relocatable anyway
    rm Install
  )

  if ! eval ${rel_dir}/bin/erl ${test_cmd}; then
    rm -rf ${rel_dir}
  fi
}

main $@
