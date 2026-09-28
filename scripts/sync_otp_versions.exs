#!/usr/bin/env elixir

defmodule Sync do
  @repo "erlef/otp_builds"

  @macos_targets ~w[
    x86_64-apple-darwin
    aarch64-apple-darwin
  ]

  @linux_targets ~w[
    x86_64-unknown-linux-gnu-ubuntu-22.04
    aarch64-unknown-linux-gnu-ubuntu-22.04
    x86_64-unknown-linux-gnu-ubuntu-24.04
    aarch64-unknown-linux-gnu-ubuntu-24.04
    x86_64-unknown-linux-gnu-ubuntu-26.04
    aarch64-unknown-linux-gnu-ubuntu-26.04
  ]

  @targets @macos_targets ++ @linux_targets

  # Tags that fail to build and should not be dispatched again.
  @skip []

  def run do
    limit = String.to_integer(System.get_env("SYNC_LIMIT", "5"))
    dry_run? = System.get_env("SYNC_DRY_RUN", "0") in ["1", "true"]
    built = Map.new(@targets, &{&1, built_tags(&1)})

    dispatches =
      for {tag, ref} <- upstream_tags(),
          tag not in @skip,
          target <- dispatch_targets(tag, built),
          do: {tag, ref, target}

    {now, later} = Enum.split(dispatches, limit)
    Enum.each(now, &dispatch(&1, dry_run?))

    if later != [] do
      IO.puts("#{length(later)} more dispatches pending")
    end
  end

  defp built_tags(target) do
    path = "builds/#{target}.csv"

    if File.exists?(path) do
      for line <- File.stream!(path),
          String.starts_with?(line, "OTP-"),
          into: MapSet.new() do
        line |> String.split(",") |> hd()
      end
    else
      MapSet.new()
    end
  end

  defp upstream_tags do
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
      {tag, ref}
    end
    |> Enum.sort_by(fn {tag, _ref} -> version_key(tag) end, :desc)
  end

  # Newest first, a final release sorts before its release candidates.
  defp version_key("OTP-" <> version) do
    case String.split(version, "-", parts: 2) do
      [version] -> {version_list(version), 1, 0}
      [version, "rc" <> rc] -> {version_list(version), 0, String.to_integer(rc)}
    end
  end

  defp version_list(version) do
    version |> String.split(".") |> Enum.map(&String.to_integer/1)
  end

  defp dispatch_targets(tag, built) do
    applicable = Enum.filter(@targets, &build_target?(&1, tag))
    missing = Enum.reject(applicable, &(tag in built[&1]))
    linux = applicable -- @macos_targets
    macos = applicable -- @linux_targets

    cond do
      missing == [] -> []
      missing == applicable -> ["all"]
      missing == linux -> ["linux"]
      missing == macos -> ["macos"]
      true -> missing
    end
  end

  # Mirrors the version rules in scripts/check_skip.bash.
  defp build_target?(target, tag) do
    cond do
      String.ends_with?(target, "-ubuntu-24.04") ->
        not String.starts_with?(tag, "OTP-25.0-rc")

      String.ends_with?(target, "-ubuntu-26.04") ->
        tag >= "OTP-26" and not String.starts_with?(tag, "OTP-26.0-rc")

      true ->
        true
    end
  end

  defp dispatch({tag, ref, target}, dry_run?) do
    IO.puts("triggering #{tag} #{ref} #{target}")

    unless dry_run? do
      {_, 0} =
        System.cmd(
          "gh",
          ~w[workflow run -R #{@repo} build.yaml -f otp-ref-name=#{tag} -f otp-ref=#{ref} -f target=#{target}],
          into: IO.stream()
        )
    end
  end
end

Sync.run()
