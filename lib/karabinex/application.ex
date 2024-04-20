defmodule Karabinex.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link(
      [Karabinex.State],
      strategy: :one_for_one,
      name: Karabinex.Supervisor
    )
  end
end
