#!/bin/bash
set -euo pipefail

main() {
  if [[ $# -ne 2 ]]; then
    cat <<USAGE
Usage:
    build_otp_linux.bash ref_name target

Example:
    OTP_REF=\$(gh api repos/erlang/otp/commits/OTP-28.1 --jq .sha) \\
      build_otp_linux.bash OTP-28.1 aarch64-unknown-linux-gnu-ubuntu-24.04
USAGE
    exit 1
  fi

  local ref_name=$1
  local target=$2

  : "${BUILD_DIR:=${PWD}/tmp/otp_builds}"
  : "${OTP_TGZ:=${BUILD_DIR}/otp-${target}.tar.gz}"

  if [[ -z "${OTP_REF+x}" ]]; then
    OTP_REF=$(gh api "repos/erlang/otp/commits/${ref_name}" --jq .sha)
  fi

  local platform
  case "${target}" in
  x86_64-unknown-linux-gnu-ubuntu-*)
    platform=linux/amd64
    ;;
  aarch64-unknown-linux-gnu-ubuntu-*)
    platform=linux/arm64
    ;;
  *)
    echo "Unknown target: ${target}"
    exit 1
    ;;
  esac

  local ubuntu_version="${target##*-ubuntu-}"
  local image="otp_builds-ubuntu-${ubuntu_version}:${platform##*/}"
  local docker_dir
  docker_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/docker" && pwd)"
  local out_dir="${BUILD_DIR}/out-${target}"

  rm -rf "${out_dir}"
  mkdir -p "${out_dir}"

  docker build \
    --platform "${platform}" \
    --tag "${image}" \
    --file "${docker_dir}/otp-ubuntu-${ubuntu_version}.dockerfile" \
    "${docker_dir}"

  docker run --rm \
    --platform "${platform}" \
    --ulimit nofile=65536:65536 \
    --env OTP_REF_NAME="${ref_name}" \
    --env OTP_REF="${OTP_REF}" \
    --volume "${out_dir}:/home/build/out" \
    "${image}"

  mv "${out_dir}/${ref_name}.tar.gz" "${OTP_TGZ}"
  rmdir "${out_dir}"

  record_library_versions "${image}" "${platform}" "${ubuntu_version}"

  # shellcheck disable=SC2310
  if ! test_otp "${ref_name}" "${platform}" "${ubuntu_version}" "${docker_dir}"; then
    rm -f "${OTP_TGZ}"
    exit 1
  fi
}

record_library_versions() {
  local image=$1
  local platform=$2
  local ubuntu_version=$3
  local wx_package

  case "${ubuntu_version}" in
  22.04)
    wx_package=libwxgtk3.0-gtk3-dev
    ;;
  *)
    wx_package=libwxgtk3.2-dev
    ;;
  esac

  local openssl_version wxwidgets_version
  openssl_version=$(package_version "${image}" "${platform}" libssl-dev)
  wxwidgets_version=$(package_version "${image}" "${platform}" "${wx_package}")
  echo "linked against openssl ${openssl_version}, wxwidgets ${wxwidgets_version}"

  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "OPENSSL_VERSION=${openssl_version}" >>"${GITHUB_ENV}"
    echo "WXWIDGETS_VERSION=${wxwidgets_version}" >>"${GITHUB_ENV}"
  fi
}

package_version() {
  local image=$1
  local platform=$2
  local package=$3

  # shellcheck disable=SC2016
  docker run --rm --platform "${platform}" "${image}" \
    dpkg-query -W -f '${source:Upstream-Version}' "${package}" | sed 's/[+~].*//'
}

test_otp() {
  local ref_name=$1
  local platform=$2
  local ubuntu_version=$3
  local docker_dir=$4

  docker run --rm \
    --platform "${platform}" \
    --volume "${OTP_TGZ}:/otp.tar.gz:ro" \
    --volume "${docker_dir}/test_otp_ubuntu.sh:/test_otp_ubuntu.sh:ro" \
    "ubuntu:${ubuntu_version}" \
    bash /test_otp_ubuntu.sh "${ref_name}"
}

main "$@"
