#!/bin/bash
set -euo pipefail

# Creates the GitHub release for an OTP ref unless it already exists and
# prints the release name.
main() {
  if [[ $# -ne 2 ]]; then
    cat <<USAGE
Usage:
    ensure_release.bash otp_ref_name otp_ref
USAGE
    exit 1
  fi

  local otp_ref_name=$1
  local otp_ref=$2
  : "${GITHUB_REPOSITORY:=erlef/otp_builds}"

  local release notes
  if [[ "${otp_ref_name}" = master ]] || [[ "${otp_ref_name}" == maint* ]]; then
    release="${otp_ref_name}-latest"
    notes="Automated build for https://github.com/erlang/otp/commit/${otp_ref}."
  else
    release="${otp_ref_name}"
    notes="Automated build for https://github.com/erlang/otp/releases/tag/${otp_ref_name}."
  fi

  # shellcheck disable=SC2310
  if release_exists "${release}"; then
    if [[ "${release}" == *latest ]]; then
      gh release edit \
        --repo "${GITHUB_REPOSITORY}" \
        --notes "${notes}" \
        "${release}" >&2
    fi
  elif ! create_release "${release}" "${notes}"; then
    # Another job may have created the release concurrently.
    # shellcheck disable=SC2310
    if ! release_exists "${release}"; then
      exit 1
    fi
  fi

  echo "${release}"
}

release_exists() {
  local release=$1

  gh release view --repo "${GITHUB_REPOSITORY}" "${release}" >/dev/null 2>&1
}

create_release() {
  local release=$1
  local notes=$2
  local extra_flags="--latest=false"

  if [[ "${release}" == *rc* ]]; then
    extra_flags="--latest=false --prerelease"
  elif [[ "${release}" != *latest ]]; then
    if [[ -f builds/aarch64-apple-darwin.csv ]]; then
      latest_version=$(cut -d"," -f1 <builds/aarch64-apple-darwin.csv | grep OTP- | sed 's/OTP-//' | sort --reverse -V | head -1)
      version=${release/OTP-/}

      if [[ $(printf "%s\n%s" "$latest_version" "$version" | sort --reverse -V | head -1) != "$latest_version" ]]; then
        extra_flags="--latest"
      fi
    fi
  fi

  # Initial commit
  local target=b5893a3c3a8d0ab54be5d04de450b24d9e5aa149

  # shellcheck disable=SC2086
  gh release create \
    --repo "${GITHUB_REPOSITORY}" \
    --title "${release}" \
    --notes "${notes}" \
    --target "${target}" \
    ${extra_flags} \
    "${release}" >&2
}

main "$@"
