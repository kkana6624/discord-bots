defmodule RoleController.MixProject do
  use Mix.Project

  def project do
    [
      app: :role_controller,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RoleController.Application, []}
    ]
  end

  defp deps do
    [
      {:nostrum, "~> 0.10", runtime: Mix.env() != :test}
    ]
  end
end
