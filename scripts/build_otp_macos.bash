#!/bin/bash
set -euo pipefail

main() {
  if [[ $# -ne 1 ]]; then
    cat <<EOF
Usage:
    build_otp_macos.bash ref_name
EOF
    exit 1
  fi

  local ref_name=$1

  case "${ref_name}" in
      OTP-25* | OTP-26.0* | OTP-26.1)
          WXWIDGETS_VERSION=disabled
          ;;
      *)
          ;;
  esac

  : "${BUILD_DIR:=${PWD}/tmp/otp_builds}"
  : "${OPENSSL_VERSION:=3.1.6}"
  : "${OPENSSL_DIR:=${BUILD_DIR}/openssl-${OPENSSL_VERSION}}"
  : "${WXWIDGETS_VERSION:=3.2.6}"
  : "${WXWIDGETS_DIR:=${BUILD_DIR}/wxwidgets-${WXWIDGETS_VERSION}}"
  : "${OTP_DIR:=${BUILD_DIR}/otp-${ref_name}-openssl-${OPENSSL_VERSION}-wxwidgets-${WXWIDGETS_VERSION}}"
  : "${OTP_TGZ:=${BUILD_DIR}/otp.tar.gz}"
  n=$(getconf _NPROCESSORS_ONLN)
  export MAKEFLAGS="-j${n}"
  export CFLAGS="-Os -fno-common -mmacosx-version-min=11.0"

  build_openssl "${OPENSSL_VERSION}"

  if [[ "${WXWIDGETS_VERSION}" != disabled ]]; then
    build_wxwidgets "${WXWIDGETS_VERSION}"
  fi

  export PATH="${WXWIDGETS_DIR}/bin:${PATH}"
  build_otp "${ref_name}"
}

build_openssl() {
  local version=$1
  local rel_dir="${OPENSSL_DIR}"
  local src_dir="${BUILD_DIR}/openssl-${version}-src"

  if [[ -d "${rel_dir}/bin" ]]; then
    echo "${rel_dir}/bin already exists, skipping build"
    "${rel_dir}/bin/openssl" version
    return
  fi

  if [[ "$version" == 3* ]]; then
    local ref_name="openssl-${version}"
  else
    local ref_name="OpenSSL_${version//./_}"
  fi
  local url="https://github.com/openssl/openssl"

  if [[ ! -d ${src_dir} ]]; then
    git clone --depth 1 "${url}" --branch "${ref_name}" "${src_dir}"
  fi

  (
    cd "${src_dir}"
    git clean -dfx
    # shellcheck disable=SC2086
    ./config no-shared --prefix="${rel_dir}" ${CFLAGS}
    make
    make install_sw
  )

  if ! "${rel_dir}/bin/openssl" version; then
    rm -rf "${rel_dir}"
  fi
}

build_wxwidgets() {
  local version=$1
  local rel_dir="${WXWIDGETS_DIR}"
  local src_dir="${BUILD_DIR}/wxwidgets-${version}-src"

  if [[ -d "${rel_dir}/bin" ]]; then
    echo "${rel_dir}/bin already exists, skipping build"
    "${rel_dir}/bin/wx-config" --version
    return
  fi

  if [[ ! -d ${src_dir} ]]; then
    curl -fsSLO "https://github.com/wxWidgets/wxWidgets/releases/download/v${version}/wxWidgets-${version}.tar.bz2"
    tar -xf "wxWidgets-${version}.tar.bz2"
    mv "wxWidgets-${version}" "${src_dir}"
    rm "wxWidgets-${version}.tar.bz2"
  fi

  (
    cd "${src_dir}"
    ./configure \
      --disable-shared \
      --prefix="${rel_dir}" \
      --with-cocoa \
      --with-macosx-version-min=11.0 \
      --disable-sys-libs
    make
    make install
  )

  if ! "${rel_dir}/bin/wx-config" --version; then
    rm -rf "${rel_dir}"
  fi
}

test_otp() {
  erl -noshell -eval 'io:format("~s~s~n", [
    erlang:system_info(system_version),
    erlang:system_info(system_architecture)]),
    {ok, _} = application:ensure_all_started(crypto), io:format("crypto ok~n"),
    halt().'

  if dyld_info "${OTP_DIR}/lib/crypto-*/priv/lib/crypto.so" | tail -n +2 | grep -q openssl; then
    echo "error: openssl dynamically linked"
    exit 1
  fi

  if [[ "${WXWIDGETS_VERSION}" != disabled ]]; then
    erl -noshell -eval '
      wx:new(), io:format("wx ok~n"),
      halt().'

    if dyld_info "${OTP_DIR}/lib/wx-*/priv/wxe_driver.so" | tail -n +2 | grep -q wxwidgets; then
      echo "error: wx dynamically linked"
      exit 1
    fi
  else
    echo wx disabled
  fi
}

build_otp() {
  local ref_name="$1"
  local rel_dir="${OTP_DIR}"
  local src_dir="${BUILD_DIR}/otp-${ref_name}-src"
  local test_dir="${OTP_DIR}-test"

  if [[ -d "${rel_dir}/bin" ]]; then
    echo "${rel_dir}/bin already exists, skipping build"

    rm -rf "${test_dir}"
    mkdir -p "${test_dir}"

    if [[ ! -f "${OTP_TGZ}" ]]; then
      build_tgz
    fi

    echo "unpacking ${OTP_TGZ} to ${test_dir}"
    tar xzf "${OTP_TGZ}" --cd "${test_dir}"
    export PATH="${test_dir}/bin:${PATH}"

    test_otp
    return
  fi

  local url="https://github.com/erlang/otp"

  if [[ ! -d "${src_dir}" ]]; then
    git clone --depth 1 "${url}" --branch "${ref_name}" "${src_dir}"
  fi

  (
    cd "${src_dir}"
    git clean -dfx
    export ERL_TOP="${PWD}"
    export ERLC_USE_SERVER=true
    export RELEASE_ROOT="${rel_dir}"
    export RELEASE_LIBBEAM=yes

    arch=$(uname -m)

    if [[ "${arch}" = "arm64" ]]; then
      if echo "${ref_name}" | grep -q "^OTP-25"; then
        jit_flags="--disable-jit"
      else
        jit_flags=""
      fi
    else
      jit_flags=""
    fi

    if [[ "${WXWIDGETS_VERSION}" = disabled ]]; then
      wxwidgets_flags="--without-{wx,observer,debugger,et}"
    else
      wxwidgets_flags=""
    fi

    case "${arch}" in
      x86_64)
        target="x86_64-apple-darwin"
        ;;
      arm64)
        target="aarch64-apple-darwin"
        ;;
      *)
        echo "Unknown architecture: ${arch}"
        exit 1
        ;;
    esac

    # shellcheck disable=SC2086
    ./otp_build configure \
      --build="${target}" \
      --host="${target}" \
      --with-ssl="${OPENSSL_DIR}" \
      --disable-dynamic-ssl-lib \
      ${jit_flags} \
      ${wxwidgets_flags}

    make release
    cd "${rel_dir}"
    ./Install -sasl "${PWD}"

    # Remove Install since the release is relocatable anyway
    rm Install
  )

  export PATH="${rel_dir}/bin:${PATH}"

  # shellcheck disable=SC2310
  if ! test_otp; then
    rm -rf "${rel_dir}"
  fi

  build_tgz
}

build_tgz() {
  echo "creating ${OTP_TGZ}"
  tar czf "${OTP_TGZ}" --cd "${OTP_DIR}" .
}

# shellcheck disable=SC2068
main $@
