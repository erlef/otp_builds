#!/bin/sh
# http://elixir-install.org/install.sh
set -eu

main() {
  otp_version="27.1.2"
  elixir_version="1.17.3"

  for arg in "$@"; do
    case "$arg" in
    elixir@*)
      elixir_version="${arg#elixir@}"
      ;;
    otp@*)
      otp_version="${arg#otp@}"
      ;;
    *)
      echo "error: invalid argument $arg" >&2
      exit 1
      ;;
    esac
  done

  root_dir="$HOME/.elixir-install"
  tmp_dir="$root_dir/tmp"
  mkdir -p "$tmp_dir"

  otp_release="${otp_version%%.*}"

  if [ "${otp_version}" = "master" ] ||
    [ "${otp_version}" = "latest" ] ||
    echo "${otp_version}" | grep -q '^maint'; then
    elixir_otp_release=27
  else
    elixir_otp_release=$otp_release
  fi

  otp_dir="$root_dir/installs/otp/$otp_version"
  elixir_dir="$root_dir/installs/elixir/$elixir_version-otp-$elixir_otp_release"

  install_otp &
  install_elixir &
  wait

  printf "checking OTP... "
  PATH="$otp_dir/bin:$PATH" export PATH
  erl -noshell -eval "io:put_chars(erlang:system_info(otp_release)), halt()."
  echo " ok"

  printf "checking Elixir... "
  "$elixir_dir/bin/elixir" -e "IO.write(System.version())"
  echo " ok"

  PATH="$elixir_dir/bin:$PATH" export PATH
  echo
  echo "Add this to your shell:"
  echo
  echo "    export PATH=\$HOME/.elixir-install/installs/otp/$otp_version/bin:\$PATH"
  echo "    export PATH=\$HOME/.elixir-install/installs/elixir/$elixir_version-otp-$elixir_otp_release/bin:\$PATH"
  echo
}

install_otp() {
  os=$(uname -s)
  case "$os" in
  Darwin) os=darwin ;;
  Linux) os=linux ;;
  MINGW64*) os=windows ;;
  *) echo "error: unsupported OS: $os." && exit 1 ;;
  esac

  arch=$(uname -m)
  case "$arch" in
  x86_64)
    macos_target=x86_64-apple-darwin
    linux_target=amd64
    ;;
  aarch64 | arm64)
    macos_target=aarch64-apple-darwin
    linux_target=arm64
    ;;
  *) echo "error: unsupported architecture: $arch." && exit 1 ;;
  esac

  if [ ! -d "$otp_dir/bin" ]; then
    if [ "$os" = "windows" ]; then
      otp_zip="otp_win64_$otp_version.zip"

      if [ ! -f "$tmp_dir/$otp_zip" ]; then
        url="https://github.com/erlang/otp/releases/download/OTP-$otp_version/$otp_zip"
        echo "downloading $url"
        curl --retry 3 -fsSLo "$tmp_dir/$otp_zip" "$url"
      fi

      echo "unpacking $otp_zip to $otp_dir..."
      mkdir -p "$otp_dir"
      unzip -q "$tmp_dir/$otp_zip" -d "$otp_dir"
      rm "$tmp_dir/$otp_zip"

      if [ ! -f /c/windows/system32/vcruntime140.dll ]; then

        echo "installing VC++ Redistributable..."
        ./vc_redist.exe /quiet /norestart
      fi
    fi

    if [ "$os" = "darwin" ]; then
      if [ "${otp_version}" = "master" ] || echo "${otp_version}" | grep -q '^maint'; then
        ref="${otp_version}-latest"
      else
        ref="OTP-${otp_version}"
      fi

      otp_tgz="otp-${macos_target}.tar.gz"

      if [ ! -f "$tmp_dir/$otp_tgz" ]; then
        if [ "${otp_version}" = "latest" ]; then
          url="https://github.com/erlef/otp_builds/releases/latest/download/$otp_tgz"
        else
          url="https://github.com/erlef/otp_builds/releases/download/$ref/$otp_tgz"
        fi
        echo "downloading $url"
        curl --retry 3 -fsSLo "$tmp_dir/$otp_tgz" "$url"
      fi

      echo "unpacking $otp_tgz to $otp_dir..."
      mkdir -p "$otp_dir"
      tar xzf "$tmp_dir/$otp_tgz" -C "$otp_dir"
      rm "$tmp_dir/$otp_tgz"
    fi

    if [ "$os" = "linux" ]; then
      if [ "${otp_version}" = "master" ] || echo "${otp_version}" | grep -q '^maint'; then
        otp_tgz="${otp_version}.tar.gz"
      else
        otp_tgz="OTP-${otp_version}.tar.gz"
      fi

      if [ ! -f "$tmp_dir/$otp_tgz" ]; then
        url="https://builds.hex.pm/builds/otp/$linux_target/ubuntu-22.04/$otp_tgz"
        echo "downloading $url"
        curl --retry 3 -fsSLo "$tmp_dir/$otp_tgz" "$url"
      fi

      echo "unpacking $otp_tgz to $otp_dir..."
      mkdir -p "$otp_dir"
      tar xzf "$tmp_dir/$otp_tgz" --strip-components 1 -C "$otp_dir"
      (cd "$otp_dir" && ./Install -sasl "$PWD")
      rm "$tmp_dir/$otp_tgz"
    fi
  fi
}

install_elixir() {
  elixir_zip="elixir-otp-$elixir_otp_release.zip"

  if [ ! -d "$elixir_dir/bin" ]; then
    if [ ! -f "$tmp_dir/$elixir_zip" ]; then
      if [ "$elixir_version" = "main" ] || echo "$elixir_version" | grep -qE '^v[0-9]+\.[0-9]+$'; then
        ref="${elixir_version}-latest"
      else
        ref="v${elixir_version}"
      fi

      if [ "${elixir_version}" = "latest" ]; then
        url="https://github.com/elixir-lang/elixir/releases/latest/download/$elixir_zip"
      else
        url="https://github.com/elixir-lang/elixir/releases/download/$ref/$elixir_zip"
      fi

      echo "downloading $url"
      curl --retry 3 -fsSLo "$tmp_dir/$elixir_zip" "$url"
    fi
    echo "unpacking $elixir_zip to $elixir_dir..."
    mkdir -p "$elixir_dir"
    unzip -q "$tmp_dir/$elixir_zip" -d "$elixir_dir"
    rm "$tmp_dir/$elixir_zip"
  fi
}

main "$@"
