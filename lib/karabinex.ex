defmodule Karabinex do
  alias Karabinex.{Config, Manipulator, ToManipulator, Validator}

  @spec write_config() :: :ok
  def write_config do
    {:ok, _} = Application.ensure_all_started(:karabinex)

    definitions =
      "rules.json"
      |> File.read!()
      |> Karabinex.JsonConfig.parse_json!()

    File.write!(
      "karabinex.json",
      %{
        title: "karabinex bindings",
        rules: [
          %{
            description: "karabinex bindings",
            manipulators: to_manipulators(definitions)
          }
        ]
      }
      |> Jason.encode!(pretty: true)
    )
  end

  @spec to_manipulators(map()) :: list()
  def to_manipulators(config_definitions) do
    config_definitions
    |> Validator.validate!()
    |> Config.preprocess()
    |> Config.parse_definitions()
    |> Enum.flat_map(&Manipulator.generate/1)
    |> capture_other_chords()
    |> Enum.map(&ToManipulator.manipulator/1)
  end

  @spec capture_other_chords([struct()]) :: [struct()]
  defp capture_other_chords(manipulators) do
    manipulators
    |> Enum.filter(&match?(%Manipulator.EnableKeymap{}, &1))
    |> Enum.map(fn %{keymap: %{chord: chord}} -> chord end)
    |> then(fn chords ->
      manipulators
      |> Enum.map(fn
        %Manipulator.EnableKeymap{} = ek ->
          Manipulator.EnableKeymap.register_other_chords(ek, chords)

        m ->
          m
      end)
    end)
  end
end
