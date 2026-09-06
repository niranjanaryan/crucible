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
      escript: [main_module: Crucible.CLI, name: "crucible"],
      aliases: ["crucible.cli": ["compile", "escript.build"]]
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto, :inets, :ssl, :public_key]]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:flame, "~> 0.5", optional: true},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ] ++ sibling(:gale)
  end

  defp sibling(name) do
    path = Path.expand("../#{name}", __DIR__)

    if System.get_env("HEX_PUBLISH") != "1" and File.dir?(path) do
      [{name, path: path, optional: true}]
    else
      []
    end
  end

  defp description do
    "Multi-cloud FLAME provisioner (Libcloud-shaped). Iroh/Zenoh join; Crucible boots."
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
        "SECURITY.md"
      ]
    ]
  end

  defp package do
    [
      name: "crucible",
      maintainers: ["Niranjan Aryan"],
      licenses: ["MIT"],
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
