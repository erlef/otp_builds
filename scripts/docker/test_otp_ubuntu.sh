#!/bin/bash
set -euo pipefail

main() {
  if [[ $# -ne 1 ]]; then
    cat <<USAGE
Usage:
    test_otp_ubuntu.sh ref_name

Expects the build at /otp.tar.gz.
USAGE
    exit 1
  fi

  local ref_name=$1

  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends ca-certificates libncurses6
  apt-get install -y --no-install-recommends libssl3t64 ||
    apt-get install -y --no-install-recommends libssl3

  mkdir -p /otp
  tar xzf /otp.tar.gz -C /otp
  cd "/otp/${ref_name}"
  export PATH="${PWD}/bin:${PATH}"

  echo "testing as extracted"
  test_erl

  echo "testing after running Install"
  ./Install -sasl "${PWD}"
  test_erl

  if ! ldd lib/crypto-*/priv/lib/crypto.so | grep -q libcrypto; then
    echo "error: crypto not linked against libcrypto"
    exit 1
  fi

  if ! ls lib/wx-*/priv/wxe_driver.so; then
    echo "error: wx not built"
    exit 1
  fi
}

test_erl() {
  erl -noshell -eval 'io:format("~s~s~n", [
    erlang:system_info(system_version),
    erlang:system_info(system_architecture)]),
    {ok, _} = application:ensure_all_started(crypto), io:format("crypto ok~n"),
    {ok, _} = code:get_doc(lists), {ok, _} = code:get_doc(edoc), io:format("docs ok~n"),
    halt().'
}

main "$@"
