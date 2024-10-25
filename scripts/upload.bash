#!/bin/bash
set -euo pipefail

usage() {
  cat<<EOF
ref_name=OTP-27.1.2; \
  OTP_REF_NAME="${ref_name}" \
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
    OTP_REF=$(gh api repos/erlang/otp/commits/${OTP_REF_NAME} --jq .sha)
  fi

  if [[ "${OTP_REF_NAME}" = master ]] || echo "${OTP_REF_NAME}" | grep -q "^maint"; then
    ref_name="${OTP_REF_NAME}-latest"
    notes="Automated build for https://github.com/erlang/otp/commit/${OTP_REF}."
  else
    ref_name="${OTP_REF_NAME}"
    notes="Automated build for https://github.com/erlang/otp/releases/tag/${OTP_REF_NAME}."
  fi

  if ! gh release view "${ref_name}"; then
    extra_flag="--latest=false"

    if echo "${ref_name}" | grep -qE 'rc'; then
      extra_flag="--prerelease"
    else
      if ! echo "${ref_name}" | grep -qE 'maint|master'; then
        if [[ -f builds/aarch64-apple-darwin.csv ]]; then
          latest_version=`cat builds/aarch64-apple-darwin.csv | cut -d"," -f1 | grep OTP- | sed 's/OTP-//' | sort --reverse -V | head -1`
          version=$(echo "$ref_name" | sed 's/OTP-//')

          if [[ $(printf "%s\n%s" "$latest_version" "$version" | sort --reverse -V | head -1) != "$latest_version" ]]; then
            extra_flag="--latest"
          fi
        fi
      fi
    fi

    # Initial commit
    target=b5893a3c3a8d0ab54be5d04de450b24d9e5aa149

    gh release create \
      --repo "${GITHUB_REPOSITORY}" \
      --title "${ref_name}" \
      --notes "${notes}" \
      --target "${target}" \
      "${extra_flag}" \
      "${ref_name}"
  fi

  arch=$(uname -m)
  case "${arch}" in
    x86_64)
      target="x86_64-apple-darwin"
      legacy_target="macos-amd64"
      ;;
    arm64)
      target="aarch64-apple-darwin"
      legacy_target="macos-arm64"
      ;;
    *)
      echo "Unknown architecture: ${arch}"
      exit 1
      ;;
  esac

  mkdir -p /tmp/otp_builds
  tgz="/tmp/otp_builds/otp-${target}.tar.gz"
  cp "${OTP_TGZ}" "${tgz}"
  legacy_tgz="/tmp/otp_builds/${OTP_REF_NAME}-${legacy_target}.tar.gz"
  cp "${OTP_TGZ}" "${legacy_tgz}"

  gh release upload \
    --repo "${GITHUB_REPOSITORY}" \
    --clobber \
    "${ref_name}" \
    "${tgz}" "${legacy_tgz}"

  if [[ -n "${ATTESTATION}" ]]; then
    cp "${ATTESTATION}" "${tgz}.sigstore"
    gh release upload \
      --repo "${GITHUB_REPOSITORY}" \
      --clobber \
      "${ref_name}" \
      "${tgz}.sigstore"
  fi

  gh workflow run update_builds.yaml \
    --repo "${GITHUB_REPOSITORY}" \
    --ref "${GITHUB_REF}" \
    --field otp-ref-name="${OTP_REF_NAME}" \
    --field otp-ref="${OTP_REF}" \
    --field openssl-version="${OPENSSL_VERSION}" \
    --field wxwidgets-version="${WXWIDGETS_VERSION}" \
    --field target="${target}"
}

main $@
