# OTP Builds

This is a collection of community-maintained [Erlang/OTP](https://github.com/erlang/otp) binary builds.

Supported operating systems:

  * `macos`

Supported architectures:

  * `amd64`
  * `arm64`

## List of Builds

List of builds can be found here:

  * `macos-amd64` - <https://github.com/erlef/otp_builds/raw/builds/macos-amd64.txt>
  * `macos-arm64` - <https://github.com/erlef/otp_builds/raw/builds/macos-arm64.txt>

Entries in the list of builds follow this pattern:

    {ref_name} {ref} {datetime} {sha256}

Where `{ref_name}` is the Erlang/OTP git tag or branch name, `{ref}` is the git sha corresponding
to the `{ref_name}`, `{datetime}` is the time the build was created and `{sha256}` is the build
SHA-256 checksum.

Example `builds/macos-arm64.txt` entry:

    OTP-27.0.1 ee9628e7ed09ef02e767994a6da5b7a225316aaa 2024-09-12T10:53:59Z a805cd23cd5362a294d1e88fa0919192b0f4cbe5601f906167c11a2b57c98ac4

## Build Downloads

Build download URLs follow this pattern:

    https://github.com/erlef/otp_builds/releases/download/{ref_name}/{ref_name}-macos-{arch}.tar.gz

Where `{ref_name}` is the name of Erlang/OTP git tag or branch name and `{arch}` is the architecture.
The supported Erlang/OTP branches are `master` and `maint`.

Example build URLs:

  * <https://github.com/erlef/otp_builds/releases/download/OTP-27.0.1/OTP-27.0.1-macos-arm64.tar.gz>
  * <https://github.com/erlef/otp_builds/releases/download/master/master-macos-amd64.tar.gz>

## License

[Apache-2.0](./LICENSE.md)
