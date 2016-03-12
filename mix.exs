defmodule Mines.Mixfile do
  use Mix.Project

  def project do
    [app: :mines,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: escript,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :cowboy], mod: {Mines, []}]
  end

  defp deps do
    [
      {:exrm, "~> 1.0"},
      {:exjson, "~> 0.5.0"},
      {:cowboy, "~> 1.0.4"},
      {:credo, "~> 0.3", only: [:dev, :test]},
      {:mock, "~> 0.1.1", only: :test}
    ]
  end

  defp escript do
    []
    # [main_module: Mines,
     # embedd_elixir: true]
  end

end
