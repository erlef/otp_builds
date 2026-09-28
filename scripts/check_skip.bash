#!/bin/bash
set -euo pipefail

main() {
  if [[ $# -ne 3 ]]; then
    cat <<USAGE
Usage:
    check_skip.bash requested_target target ref_name

Writes SKIP=true to \$GITHUB_ENV when the build should not run.
USAGE
    exit 1
  fi

  local requested_target=$1
  local target=$2
  local ref_name=$3

  # shellcheck disable=SC2310
  if ! target_requested "${requested_target}" "${target}"; then
    skip "${target} not requested (${requested_target})"
  fi

  local major
  major=$(otp_major "${ref_name}")

  if [[ -n "${major}" && "${major}" -lt 25 ]]; then
    skip "${ref_name} is older than OTP-25"
  fi

  case "${target}" in
  *-ubuntu-24.04)
    if [[ "${ref_name}" == OTP-25.0-rc* ]]; then
      skip "${ref_name} is not built on ubuntu-24.04"
    fi
    ;;
  *-ubuntu-26.04)
    if [[ -n "${major}" && "${major}" -lt 26 ]] || [[ "${ref_name}" == OTP-26.0-rc* ]]; then
      skip "${ref_name} is not built on ubuntu-26.04"
    fi
    ;;
  *) ;;
  esac

  echo "building ${ref_name} for ${target}"
}

target_requested() {
  local requested=$1
  local target=$2

  case "${requested}" in
  all)
    return 0
    ;;
  linux)
    [[ "${target}" == *-linux-gnu-* ]]
    ;;
  macos)
    [[ "${target}" == *-apple-darwin ]]
    ;;
  *)
    [[ "${requested}" == "${target}" ]]
    ;;
  esac
}

# Prints the OTP major version, or nothing for master and maint.
otp_major() {
  local ref_name=$1

  if [[ "${ref_name}" =~ ^maint-([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "${ref_name}" =~ ^OTP-([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  fi
}

skip() {
  echo "skipping: $1"

  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "SKIP=true" >>"${GITHUB_ENV}"
  fi

  exit 0
}

main "$@"
