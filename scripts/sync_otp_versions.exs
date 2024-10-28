#!/usr/bin/env elixir

tags =
  for line <- File.stream!("builds/aarch64-apple-darwin.csv"),
      String.starts_with?(line, "OTP-"),
      into: MapSet.new() do
    line |> String.split(",") |> hd()
  end

{lines, 0} =
  System.cmd(
    "git",
    ["ls-remote", "--tags", "https://github.com/erlang/otp.git"],
    lines: 2048,
    into: []
  )

for line <- lines,
    [ref, "refs/tags/" <> tag] = String.split(line, "\t"),
    tag =~ ~r/OTP-(.*)\d$/,
    tag >= "OTP-25" do
  if tag not in tags do
    IO.puts("triggering #{tag} #{ref}")

    {_, 0} =
      System.cmd(
        "gh",
        ~w[workflow run -R erlef/otp_builds build.yaml -f otp-ref-name=#{tag} -f otp-ref=#{ref}],
        into: IO.stream()
      )
  end
end
