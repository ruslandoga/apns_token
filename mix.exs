defmodule APNSToken.MixProject do
  use Mix.Project

  def project do
    [
      app: :apns_token,
      version: "0.1.0-rc.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
