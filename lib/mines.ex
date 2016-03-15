alias Mines.GameRegistry
alias Mines.Server.{Http, Telnet}

defmodule Mines do
  use Application

  def start do
    start(:normal, [])
  end

  def start(_type, _args) do

    import Supervisor.Spec

    registry =
      if master do
        Node.connect(String.to_atom(master))
        []
      else
        :ok = GameRegistry.Mnesia.install
        [worker(GameRegistry.Mnesia, [], restart: :permanent)]
      end

    children = [
      supervisor(Http.Supervisor, [port: http_port]),
      supervisor(Telnet.Supervisor, [port: telnet_port])
    ] ++ registry

    opts = [strategy: :one_for_one, name: Mines.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def master,
    do: System.get_env("MINES_MASTER")

  def telnet_port,
    do: (System.get_env("MINES_TELNET") || "2222") |> String.to_integer

  def http_port,
    do: (System.get_env("MINES_HTTP") || "8080") |> String.to_integer

end
