defmodule Crucible.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/niranjanaryan/crucible"

  def project do
    [
      app: :crucible,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: description(),
      source_url: @source_url,
      homepage_url: "https://hex.pm/packages/crucible",
      name: "Crucible",
      escript: [
        main_module: Crucible.CLI,
        name: "crucible",
        embed_elixir: true,
        comment: "crucible standalone CLI"
      ],
      releases: releases(),
      aliases: ["crucible.cli": ["compile", "escript.build"]]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :inets, :ssl, :public_key],
      mod: {Crucible.Application, []}
    ]
  end

  def wrap(%Mix.Release{} = release) do
    if Code.ensure_loaded?(Burrito), do: Burrito.wrap(release), else: release
  end

  defp releases do
    [
      crucible: [
        steps: [:assemble, &__MODULE__.wrap/1],
        burrito: [targets: burrito_targets()]
      ]
    ]
  end

  defp burrito_targets do
    [
      macos: [os: :darwin, cpu: :x86_64, skip_nifs: true],
      macos_silicon: [os: :darwin, cpu: :aarch64, skip_nifs: true],
      linux: [os: :linux, cpu: :x86_64, skip_nifs: true],
      linux_aarch64: [os: :linux, cpu: :aarch64, skip_nifs: true],
      windows: [os: :windows, cpu: :x86_64, skip_nifs: true]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:flame, "~> 0.5", optional: true},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:burrito, "~> 1.6", optional: true, runtime: false}
    ]
  end

  defp description do
    "Multi-cloud provisioner CLI and Phoenix FLAME backend. Boot and remove VMs across AWS, Hetzner, DigitalOcean, Vultr, Linode, Civo, Scaleway, and more from Elixir."
  end

  defp docs do
    [
      main: "Crucible",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "DESIGN.md",
        "LIBCLOUD.md",
        "CHANGELOG.md",
        "LICENSE",
        "FUNDING.md",
        "CONTRIBUTING.md",
        "SECURITY.md",
        "PRODUCTION.md"
      ]
    ]
  end

  defp package do
    [
      name: "crucible",
      maintainers: ["Niranjan Aryan"],
      licenses: ["MIT"],
      keywords: [
        "cloud",
        "provisioner",
        "flame",
        "phoenix",
        "hetzner",
        "aws",
        "gcp",
        "azure",
        "cli",
        "libcloud",
        "iroh",
        "zenoh",
        "devops"
      ],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "HexDocs" => "https://hexdocs.pm/crucible",
        "Sponsor" => "https://github.com/sponsors/niranjanaryan",
        "Gale" => "https://github.com/niranjanaryan/gale",
        "Ingot" => "https://github.com/niranjanaryan/ingot",
        "Dusk" => "https://github.com/niranjanaryan/dusk",
        "Zeiroh" => "https://github.com/niranjanaryan/zeiroh",
        "Orian" => "https://github.com/niranjanaryan/orian"
      },
      files: ~w(
        lib mix.exs mix.lock README.md DESIGN.md LIBCLOUD.md LICENSE CHANGELOG.md
        FUNDING.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md .formatter.exs
      )
    ]
  end
end
