defmodule PhoenixVite.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/phoenixframework/phoenix_vite"

  def project do
    [
      app: :phoenix_vite,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      docs: docs(),
      name: "PhoenixVite",
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 3.3 or ~> 4.0"},
      {:jason, "~> 1.2"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Phoenix integration for Vite - a fast frontend build tool.
    """
  end

  defp package do
    [
      name: "phoenix_vite",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      },
      files: ~w(
        lib
        priv
        mix.exs
        README.md
        LICENSE
        CHANGELOG.md
        .formatter.exs
      )
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
