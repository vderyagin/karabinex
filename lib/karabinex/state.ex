defmodule Karabinex.State do
  use Agent

  def start_link(_) do
    Agent.start_link(&initial_value/0, name: __MODULE__)
  end

  def initial_value, do: %{key_codes: key_codes()}

  def key_codes do
    :code.priv_dir(:karabinex)
    |> Path.join("/simple_modifications.json")
    |> File.read!()
    |> Jason.decode!(keys: :atoms)
    |> Enum.reduce(%{}, fn
      %{data: [%{key_code: code}]}, acc ->
        Map.update(acc, :regular, MapSet.new(), &MapSet.put(&1, code))

      %{data: [%{consumer_key_code: code}]}, acc ->
        Map.update(acc, :consumer, MapSet.new(), &MapSet.put(&1, code))

      %{data: [%{pointing_button: code}]}, acc ->
        Map.update(acc, :pointer, MapSet.new(), &MapSet.put(&1, code))

      _, acc ->
        acc
    end)
  end

  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end
end
