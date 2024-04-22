defmodule Karabinex do
  alias Karabinex.{Rules, Config, Manipulator}

  def write_config do
    {:ok, _} = Application.ensure_all_started(:karabinex)

    manipulators =
      Rules.rules()
      |> Config.parse_definitions()
      |> Enum.flat_map(&Manipulator.generate/1)

    File.write!(
      "./karabiner.json",
      %{
        title: "Nested Emacs-like bindings",
        rules: [
          %{
            description: "Nested Emacs-like bindings",
            manipulators: manipulators
          }
        ]
      }
      |> Jason.encode!(pretty: true)
    )
  end
end
