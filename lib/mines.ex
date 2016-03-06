alias Mines.GameRegistry
alias Mines.Server.Telnet

defmodule Mines do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    GameRegistry.init

    children = [
      worker(Telnet.Supervisor, [port: 2323])
    ]

    opts = [strategy: :one_for_one, name: Mines.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
