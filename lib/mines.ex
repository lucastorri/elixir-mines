alias Mines.GameRegistry
alias Mines.Server.{Http, Telnet}

defmodule Mines do
  use Application

  def start do
    start(:normal, [])
  end

  def start(_type, _args) do
    import Supervisor.Spec

    GameRegistry.init

    children = [
      supervisor(Http.Supervisor, [port: 8081]),
      supervisor(Telnet.Supervisor, [port: 2223])
    ]

    opts = [strategy: :one_for_one, name: Mines.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
