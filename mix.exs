defmodule Karabinex.MixProject do
  use Mix.Project

  def project do
    [
      app: :karabinex,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: [
        {:jason, "~> 1.4"},
        {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
      ],
      dialyzer: dialyzer_config()
    ]
  end

  defp dialyzer_config do
    # https://erlang.org/doc/man/dialyzer.html
    [
      flags: [
        :unmatched_returns,
        :error_handling,
        :extra_return,
        :missing_return,
        :underspecs,
        :overspecs,
        :unknown,
        :specdiffs
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
