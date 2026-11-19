#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
ref_name=OTP-27.1.2; \
  OTP_REF_NAME="${ref_name}" \
  TARGET=aarch64-apple-darwin \
  OPENSSL_VERSION=3.1.6 \
  WXWIDGETS_VERSION=3.2.6 \
  ./scripts/upload.bash
EOF
}

main() {
  : "${GITHUB_REPOSITORY:=erlef/otp_builds}"
  : "${GITHUB_REF:=main}"
  : "${BUILD_DIR:=${PWD}/tmp/otp_builds}"
  : "${OTP_TGZ:=${BUILD_DIR}/otp.tar.gz}"
  : "${ATTESTATION:=}"

  if [[ -z "${OTP_REF+x}" ]]; then
    OTP_REF=$(gh api "repos/erlang/otp/commits/${OTP_REF_NAME}" --jq .sha)
  fi

  if [[ -z "${TARGET:-}" ]]; then
    case "$(uname -sm)" in
    "Darwin x86_64")
      TARGET="x86_64-apple-darwin"
      ;;
    "Darwin arm64")
      TARGET="aarch64-apple-darwin"
      ;;
    *)
      echo "TARGET not set"
      exit 1
      ;;
    esac
  fi

  case "${TARGET}" in
  x86_64-apple-darwin)
    legacy_target="macos-amd64"
    ;;
  aarch64-apple-darwin)
    legacy_target="macos-arm64"
    ;;
  *)
    legacy_target=""
    ;;
  esac

  release=$("$(dirname "${BASH_SOURCE[0]}")/ensure_release.bash" "${OTP_REF_NAME}" "${OTP_REF}")

  mkdir -p /tmp/otp_builds
  tgz="/tmp/otp_builds/otp-${TARGET}.tar.gz"
  if [[ "${OTP_TGZ}" != "${tgz}" ]]; then
    cp "${OTP_TGZ}" "${tgz}"
  fi
  files=("${tgz}")

  if [[ -n "${legacy_target}" ]]; then
    legacy_tgz="/tmp/otp_builds/${OTP_REF_NAME}-${legacy_target}.tar.gz"
    cp "${OTP_TGZ}" "${legacy_tgz}"
    files+=("${legacy_tgz}")
  fi

  gh release upload \
    --repo "${GITHUB_REPOSITORY}" \
    --clobber \
    "${release}" \
    "${files[@]}"

  if [[ -n "${ATTESTATION}" ]]; then
    cp "${ATTESTATION}" "${tgz}.sigstore"
    gh release upload \
      --repo "${GITHUB_REPOSITORY}" \
      --clobber \
      "${release}" \
      "${tgz}.sigstore"
  fi

  gh workflow run update_builds.yaml \
    --repo "${GITHUB_REPOSITORY}" \
    --ref "${GITHUB_REF}" \
    --field otp-ref-name="${OTP_REF_NAME}" \
    --field otp-ref="${OTP_REF}" \
    --field openssl-version="${OPENSSL_VERSION}" \
    --field wxwidgets-version="${WXWIDGETS_VERSION}" \
    --field target="${TARGET}"
}

main "$@"
