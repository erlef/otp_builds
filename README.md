# OTP Builds

> [!WARNING]
> This is a work in progress.

This is a collection of community-maintained [Erlang/OTP](https://github.com/erlang/otp) binary builds.

Supported operating systems:

  * `darwin` (macOS)

Supported architectures:

  * `x86_64`
  * `aarch64`

The goal of these builds is to be as self-contained as possible. OpenSSL (used by `crypto` app) and wxWidgets (used by `wx` app and it's dependants, `observer`, `debugger`, and `et`) are statically linked.

## List of Builds

| Target                              | OpenSSL | wxWidgets                 |
| ----------------------------------- | ------- | ------------------------- |
| **OTP 25**                          |         |                           |
| `x86_64-apple-darwin`               | 3.1.6   | N/A <sup>2</sup>          |
| `aarch64-apple-darwin` <sup>1</sup> | 3.1.6   | N/A <sup>2</sup>          |
| **OTP 26**                          |         |                           |
| `*-apple-darwin`                    | 3.1.6   | N/A <sup>2</sup> / 3.2.5  |
| **OTP 27**                          |         |                           |
| `*-apple-darwin`                    | 3.1.6   | 3.2.5                     |
| **OTP maint** <sup>3</sup>          |         |                           |
| `*-apple-darwin`                    | 3.1.6   | 3.2.5                     |
| **OTP master** <sup>3</sup>         |         |                           |
| `*-apple-darwin`                    | 3.1.6   | 3.2.5                     |

<sup>1</sup> JIT is disabled on OTP 25 on `aarch64-apple-darwin`.

<sup>2</sup> `wx`, `observer`, `debugger`, and `et` apps are only available since OTP 26.1.1.

<sup>3</sup> OTP maint and master builds are updated daily.

List of builds can be found here:

  * `x86_64-apple-darwin` - <https://github.com/erlef/otp_builds/raw/builds/x86_64-apple-darwin.csv>
  * `aarch64-apple-darwin` - <https://github.com/erlef/otp_builds/raw/builds/aarch64-apple-darwin.csv>

Entries in the list of builds follow this pattern:

    {ref_name},{ref},{datetime},{sha256},{openssl_version},{wxwidgets_version}

Where `{ref_name}` is the Erlang/OTP git tag or branch name, `{ref}` is the git sha corresponding to the `{ref_name}`, `{datetime}` is the time the build was created and `{sha256}` is the build SHA-256 checksum. The `{openssl_version}` and `{wxwidgets_version}` are versions that we are statically linking with.

Example `builds/aarch64-apple-darwin.csv` entry:

    OTP-27.0.1,ee9628e7ed09ef02e767994a6da5b7a225316aaa,2024-09-12T10:53:59Z,a805cd23cd5362a294d1e88fa0919192b0f4cbe5601f906167c11a2b57c98ac4

## Build Downloads

Build download URLs follow this pattern:

    https://github.com/erlef/otp_builds/releases/download/{ref_name}/{ref_name}-{target}.tar.gz

Where `{ref_name}` is the name of Erlang/OTP git tag or branch name and `{target}` is the target triple (e.g. `aarch64-apple-darwin`). The supported Erlang/OTP branches are `master` and `maint`.

Example build URLs:

  * <https://github.com/erlef/otp_builds/releases/download/OTP-27.0.1/OTP-27.0.1-aarch64-apple-darwin.tar.gz>
  * <https://github.com/erlef/otp_builds/releases/download/master/master-x86_64-apple-darwin.tar.gz>

After downloading the build you should verify its integrity against builds csv mentioned in the previous section, for example:

    $ curl -fLO https://github.com/erlef/otp_builds/releases/download/OTP-27.1.2/OTP-27.1.2-aarch64-apple-darwin.tar.gz
    $ checksum=`curl -fsSL https://github.com/erlef/otp_builds/raw/builds/aarch64-apple-darwin.csv | grep OTP-27.1.2, | cut -d"," -f4`
    $ sha256 OTP-27.1.2-aarch64-apple-darwin.tar.gz --check $checksum

## License

[Apache-2.0](./LICENSE.md)
