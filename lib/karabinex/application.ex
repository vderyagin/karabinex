defmodule Karabinex.Application do
  use Application

  @impl Application
  @spec start(Application.start_type(), term()) :: {:ok, pid()} | {:error, term()}
  def start(_type, _args) do
    Supervisor.start_link(
      [Karabinex.State],
      strategy: :one_for_one,
      name: Karabinex.Supervisor
    )
  end
end
