defmodule Karabinex do
  alias Karabinex.{Rules, Config, Manipulator}

  def write_config(definition_name) do
    {:ok, _} = Application.ensure_all_started(:karabinex)

    {description, definitions} = Rules.definition(definition_name)

    manipulators =
      definitions
      |> Config.parse_definitions()
      |> Enum.flat_map(&Manipulator.generate/1)

    File.write!(
      "#{definition_name}.json",
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
