defmodule Karabinex do
  alias Karabinex.{Config, Manipulator}

  def write_config do
    {:ok, _} = Application.ensure_all_started(:karabinex)

    opts = [file: "rules.exs"]

    {{description, definitions}, _binding} =
      File.read!(opts[:file])
      |> Code.string_to_quoted!(opts)
      |> Code.eval_quoted([], opts)

    manipulators =
      definitions
      |> Config.parse_definitions()
      |> Enum.flat_map(&Manipulator.generate/1)

    File.write!(
      "karabinex.json",
      %{
        title: description,
        rules: [
          %{
            description: description,
            manipulators: manipulators
          }
        ]
      }
      |> Jason.encode!(pretty: true)
    )
  end
end
