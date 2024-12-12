# OTP Builds

This is a collection of community-maintained
[Erlang/OTP](https://github.com/erlang/otp) binary builds.

Supported operating systems:

* `darwin` (macOS)

Supported architectures:

* `x86_64`
* `aarch64`

The goal of these builds is to be as self-contained as possible. OpenSSL (used by `crypto` app)
and wxWidgets (used by `wx` app and its dependants, `observer`, `debugger`, and `et`) are
statically linked.

## List of Builds

| Target                  | OpenSSL | wxWidgets            |
|-------------------------|---------|----------------------|
| **OTP 25**              |         |                      |
| `x86_64-apple-darwin`   | 1.1.1w  | N/A²                 |
| `aarch64-apple-darwin`¹ | 1.1.1w  | N/A²                 |
| **OTP 26**              |         |                      |
| `*-apple-darwin`        | 3.1.6   | N/A² / 3.2.5         |
| **OTP 27**              |         |                      |
| `*-apple-darwin`        | 3.1.6   | 3.2.5                |
| **OTP maint**³          |         |                      |
| `*-apple-darwin`        | 3.1.6   | 3.2.5                |
| **OTP master**³         |         |                      |
| `*-apple-darwin`        | 3.1.6   | 3.2.5                |

¹ JIT is disabled on OTP 25 on `aarch64-apple-darwin`.

² `wx`, `observer`, `debugger`, and `et` apps are only available since OTP 26.1.1.

³ OTP `maint`, `maint-25`, `maint-26`, `maint-27`, and `master` builds are updated daily.

List of builds can be found here:

* `x86_64-apple-darwin` - <https://github.com/erlef/otp_builds/raw/main/builds/x86_64-apple-darwin.csv>
* `aarch64-apple-darwin` - <https://github.com/erlef/otp_builds/raw/main/builds/aarch64-apple-darwin.csv>

Entries in the list of builds follow this pattern:

    {ref_name},{ref},{datetime},{sha256},{openssl_version},{wxwidgets_version}

Where `{ref_name}` is the Erlang/OTP git tag or branch name, `{ref}` is the git sha corresponding
to the `{ref_name}`, `{datetime}` is the time the build was created and `{sha256}` is the build
SHA-256 checksum. The `{openssl_version}` and `{wxwidgets_version}` are versions that we are
statically linking with.

Example `builds/aarch64-apple-darwin.csv` entry:

    OTP-27.1.2,44ffe8811dfcf3d2fe04d530c6e8fac5ca384e02,2024-10-23T21:02:30Z,9c49d2dc3f0f073b58d7ae9f6cfbcc422dafdb3a85351dcb8efdab3632b4413c,openssl-3.1.6,wxwidgets-3.2.6

## Build Downloads

Build download URLs follow this pattern:

    https://github.com/erlef/otp_builds/releases/download/{ref_name}/otp-{target}.tar.gz

Where `{ref_name}` is the name of Erlang/OTP release or branch and `{target}` is the target
triple. Supported branch names are `maint-latest`, `maint-25-latest`, `maint-26-latest`,
`maint-27-latest`, and `master-latest` which correspond to Erlang/OTP `maint`, `maint-25`,
`maint-26`, `maint-27`, and `master` branches.

Example build URLs:

* <https://github.com/erlef/otp_builds/releases/download/master-latest/otp-x86_64-apple-darwin.tar.gz>
* <https://github.com/erlef/otp_builds/releases/download/OTP-27.0.1/otp-aarch64-apple-darwin.tar.gz>

To download from the _latest_ release, use this URL:

* <https://github.com/erlef/otp_builds/releases/latest/download/otp-aarch64-apple-darwin.tar.gz>

After downloading the build you should verify its integrity against builds csv mentioned in the
previous section, for example:

    curl -fLO https://github.com/erlef/otp_builds/releases/download/OTP-27.1.2/otp-aarch64-apple-darwin.tar.gz
    checksum=$(curl -fsSL https://github.com/erlef/otp_builds/raw/main/builds/aarch64-apple-darwin.csv | grep OTP-27.1.2, | cut -d"," -f4)
    echo "$checksum otp-aarch64-apple-darwin.tar.gz" | sha256sum --check

## License

[Apache-2.0](./LICENSE.txt)
