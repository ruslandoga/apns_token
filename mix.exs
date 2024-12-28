defmodule APNSToken.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo_url "https://github.com/ruslandoga/apns_token"

  def project do
    [
      app: :apns_token,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # hex
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => @repo_url}
      ],
      description: "Tiny APNs token generator",
      # docs
      name: "APNSToken",
      docs: [
        source_url: @repo_url,
        source_ref: "v#{@version}",
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"],
        skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jose, "~> 1.11"},
      {:jason, "~> 1.4", optional: true},
      {:ex_doc, "~> 0.34.2", only: :dev},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
  end
end
