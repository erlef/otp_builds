# OTP Builds

This is a collection of community-maintained
[Erlang/OTP](https://github.com/erlang/otp) binary builds.

Supported operating systems:

* `darwin` (macOS)
* `linux` (Ubuntu 22.04, 24.04, and 26.04)

Supported architectures:

* `x86_64`
* `aarch64`

The goal of the macOS builds is to be as self-contained as possible. OpenSSL (used by `crypto`
app) and wxWidgets (used by `wx` app and its dependants, `observer`, `debugger`, and `et`) are
statically linked.

The Linux builds are made for a specific Ubuntu release and dynamically link against its OpenSSL
and wxWidgets packages, see [Linux Builds](#linux-builds).

## List of Builds

List of builds can be found here:

* `x86_64-apple-darwin` - <https://github.com/erlef/otp_builds/blob/main/builds/x86_64-apple-darwin.csv>
* `aarch64-apple-darwin` - <https://github.com/erlef/otp_builds/blob/main/builds/aarch64-apple-darwin.csv>
* `x86_64-unknown-linux-gnu-ubuntu-22.04` -
  <https://github.com/erlef/otp_builds/blob/main/builds/x86_64-unknown-linux-gnu-ubuntu-22.04.csv>
* `aarch64-unknown-linux-gnu-ubuntu-22.04` -
  <https://github.com/erlef/otp_builds/blob/main/builds/aarch64-unknown-linux-gnu-ubuntu-22.04.csv>
* `x86_64-unknown-linux-gnu-ubuntu-24.04` -
  <https://github.com/erlef/otp_builds/blob/main/builds/x86_64-unknown-linux-gnu-ubuntu-24.04.csv>
* `aarch64-unknown-linux-gnu-ubuntu-24.04` -
  <https://github.com/erlef/otp_builds/blob/main/builds/aarch64-unknown-linux-gnu-ubuntu-24.04.csv>
* `x86_64-unknown-linux-gnu-ubuntu-26.04` -
  <https://github.com/erlef/otp_builds/blob/main/builds/x86_64-unknown-linux-gnu-ubuntu-26.04.csv>
* `aarch64-unknown-linux-gnu-ubuntu-26.04` -
  <https://github.com/erlef/otp_builds/blob/main/builds/aarch64-unknown-linux-gnu-ubuntu-26.04.csv>

Entries in the list of builds follow this pattern:

    {ref_name},{ref},{datetime},{sha256},{openssl_version},{wxwidgets_version}

Where `{ref_name}` is the Erlang/OTP git tag or branch name, `{ref}` is the git sha corresponding
to the `{ref_name}`, `{datetime}` is the time the build was created and `{sha256}` is the build
SHA-256 checksum. The `{openssl_version}` and `{wxwidgets_version}` are the versions the macOS
builds statically link with, and the Ubuntu package versions the Linux builds were compiled
against. Linux builds imported from builds.hex.pm only record the package series, for example
`openssl-3.0`.

Example `builds/aarch64-apple-darwin.csv` entry:

```csv
OTP-27.1.2,44ffe8811dfcf3d2fe04d530c6e8fac5ca384e02,2024-10-23T21:02:30Z,9c49d2dc3f0f073b58d7ae9f6cfbcc422dafdb3a85351dcb8efdab3632b4413c,openssl-3.1.6,wxwidgets-3.2.6
```

### Legacy List of Builds

For the Linux targets a `builds/{target}.txt` file is kept next to the csv, for example
<https://github.com/erlef/otp_builds/blob/main/builds/x86_64-unknown-linux-gnu-ubuntu-24.04.txt>.
It is the list format previously served by builds.hex.pm ([hexpm/bob](https://github.com/hexpm/bob))
and only exists for compatibility with tools that read those lists. Entries follow this pattern:

    {ref_name} {ref} {datetime} {sha256}

The file is generated from the csv and contains no information that is not in the csv, use the
csv for anything new.

## Build Downloads

Build download URLs follow this pattern:

    https://github.com/erlef/otp_builds/releases/download/{ref_name}/otp-{target}.tar.gz

Where `{ref_name}` is the name of Erlang/OTP release or branch and `{target}` is the target
triple. Supported branch names are `maint-latest`, `maint-25-latest`, `maint-26-latest`,
`maint-27-latest`, `maint-28-latest`, and `master-latest` which correspond to Erlang/OTP `maint`,
`maint-25`, `maint-26`, `maint-27`, `maint-28`, and `master` branches.

Example build URLs:

* <https://github.com/erlef/otp_builds/releases/download/master-latest/otp-x86_64-apple-darwin.tar.gz>
* <https://github.com/erlef/otp_builds/releases/download/OTP-27.0.1/otp-aarch64-apple-darwin.tar.gz>
* <https://github.com/erlef/otp_builds/releases/download/OTP-27.0.1/otp-x86_64-unknown-linux-gnu-ubuntu-24.04.tar.gz>

To download from the _latest_ release, use this URL:

* <https://github.com/erlef/otp_builds/releases/latest/download/otp-aarch64-apple-darwin.tar.gz>

After downloading the build you should verify its integrity against builds csv mentioned in the
previous section, for example:

    curl -fLO https://github.com/erlef/otp_builds/releases/download/OTP-27.1.2/otp-aarch64-apple-darwin.tar.gz
    checksum=$(curl -fsSL https://github.com/erlef/otp_builds/raw/main/builds/aarch64-apple-darwin.csv | grep OTP-27.1.2, | cut -d"," -f4)
    shasum -a 256 -c <<< "$checksum  otp-aarch64-apple-darwin.tar.gz"

## Linux Builds

Linux builds are compiled on the Ubuntu release named in the target and are meant to run on that
release. They dynamically link against the distribution's OpenSSL and wxWidgets, so these runtime
packages need to be installed: `libssl3` (`libssl3t64` on Ubuntu 24.04 and later), `libncurses6`,
and for the `wx` app `libwxgtk3.0-gtk3-0v5` on Ubuntu 22.04 or `libwxgtk3.2-1t64` and
`libwxgtk-webview3.2-1t64` on Ubuntu 24.04 and later.

The tarball contains a `{ref_name}` directory with the Erlang/OTP release, which is ready to use
after extracting:

    curl -fLO https://github.com/erlef/otp_builds/releases/download/OTP-27.1.2/otp-x86_64-unknown-linux-gnu-ubuntu-24.04.tar.gz
    checksum=$(curl -fsSL https://github.com/erlef/otp_builds/raw/main/builds/x86_64-unknown-linux-gnu-ubuntu-24.04.csv | grep OTP-27.1.2, | cut -d"," -f4)
    sha256sum -c <<< "$checksum  otp-x86_64-unknown-linux-gnu-ubuntu-24.04.tar.gz"
    tar xzf otp-x86_64-unknown-linux-gnu-ubuntu-24.04.tar.gz
    export PATH="$PWD/OTP-27.1.2/bin:$PATH"

The `Install` script is kept in the tarball. Tools written for the builds.hex.pm tarballs run
`./Install -sasl $PWD` after extracting, which continues to work.

Builds are available for these Erlang/OTP versions:

* Ubuntu 22.04: OTP-25 and later
* Ubuntu 24.04: OTP-25 and later, except OTP-25.0 release candidates
* Ubuntu 26.04: OTP-26 and later, except OTP-26.0 release candidates

Builds imported from builds.hex.pm, previously made by [hexpm/bob](https://github.com/hexpm/bob),
keep their original build time in the list of builds and have no `.sigstore` attestation.

## Differences Between macOS and Linux Builds

The Linux builds keep the shape of the builds previously served by builds.hex.pm, so the two
kinds of tarball differ:

| | macOS | Linux |
| --- | --- | --- |
| Layout | `bin/`, `lib/`, `erts-*/` at the root of the tarball | A single `{ref_name}/` directory |
| `Install` | Already run and removed | Already run and kept, running it again is harmless |
| OpenSSL and wxWidgets | Statically linked, versions in the list of builds | Dynamically linked against the Ubuntu packages, see above |
| `wx` | Not built for OTP-25, OTP-26.0, and OTP-26.1 | Built for all versions |

Both are relocatable and include documentation chunks in `lib/*/doc/chunks` for OTP-25 and
OTP-26. From OTP-27 the documentation is embedded in the `.beam` files in all applications except edoc.

The Linux layout may be changed to the macOS one in the future, at which point the
builds.hex.pm-style tarballs will be deprecated.

## License

[Apache-2.0](./LICENSE.txt)
