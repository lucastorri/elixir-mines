require Logger

alias Mines.Server.Response
alias Mines.Server.Telnet
alias Mines.Server.Telnet.State
alias Mines.Server.Telnet.Handler

defmodule Mines.Server.Telnet.Supervisor do
  use Supervisor
  @behaviour Mines.Server.Supervisor

  @tcp_options [:binary, packet: :line, active: false, reuseaddr: true]
  @defaults [port: 2222]

  def start_link do
    start_link([])
  end

  def start_link(arg = {_, _}) do
    start_link([arg])
  end

  def start_link(args) do
    args = Keyword.merge(@defaults, is_list(args) && args || [])
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    with {:ok, socket} <- :gen_tcp.listen(args[:port], @tcp_options) do
      children = [
        worker(Telnet, [socket], restart: :permanent)
      ]
      supervise(children, strategy: :one_for_one)
    end
  end

end

defmodule Mines.Server.Telnet.State do

  defstruct socket: nil, accepting: 0, handling: 0

  def update(state, increments) do
    %{state |
      accepting: state.accepting + (increments[:accepting] || 0),
      handling: state.handling + (increments[:handling] || 0)}
  end

end

defmodule Mines.Server.Telnet do
  use GenServer

  @min_accepting_handlers 5
  @max_handling_handlers 10

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init(socket) do
    Logger.debug "Starting Server"
    state = %State{socket: socket}
    {:ok, check(state)}
  end

  def handle_cast(message, state) do
    Logger.debug "Server: #{message}"
    increments = case message do
      :handler_accepting -> [accepting: +1]
      :handler_handling -> [accepting: -1, handling: +1]
      :handler_exiting -> [handling: -1]
    end
    new_state = State.update(state, increments)
    {:noreply, check(new_state)}
  end

  defp check(state) do

    total_handlers = state.accepting + state.handling
    if state.accepting < @min_accepting_handlers and
       total_handlers < @max_handling_handlers,
       do: new_handler(state)

    state
  end

  defp new_handler(state) do
    Handler.start_link(self, state.socket)
  end

end

defmodule Mines.Server.Telnet.Handler do
  use GenServer

  def start_link(server, socket) do
    GenServer.start_link(__MODULE__, [server, socket])
  end

  def init([server, socket]) do
    GenServer.cast(self, :accept)
    {:ok, {server, socket}}
  end

  def handle_cast(:accept, {server, socket}) do
    GenServer.cast(server, :handler_accepting)
    case :gen_tcp.accept(socket) do
      {:ok, conn} ->
        GenServer.cast(server, :handler_handling)
        GenServer.cast(self, :handle)
        {:ok, handler} = Mines.Server.Handler.start_link(fn res ->
          render(res) |> reply(conn)
        end)
        {:noreply, {server, conn, handler}}
      {:error, err} ->
        {:stop, err, socket}
    end
  end

  def handle_cast(:handle, state = {server, conn, handler}) do
    case :gen_tcp.recv(conn, 0) do
      {:ok, input} ->
        GenServer.cast(self, :handle)
        cmd = input |> String.strip |> parse
        Mines.Server.Handler.command(handler, cmd)
        {:noreply, state}
      {:error, :closed} ->
        GenServer.cast(server, :handler_exiting)
        {:stop, :normal, state}
      {:error, err} ->
        GenServer.cast(server, :handler_exiting)
        {:stop, err, state}
    end
  end

  defp reply(message, conn) do
    :gen_tcp.send(conn, message)
    :gen_tcp.send(conn, "\n")
  end

  defp render(response) do
    case response do
      %Response{msg: nil, state: nil} -> ""
      %Response{msg: nil, state: state} -> render_state(state)
      %Response{msg: msg, state: nil} -> msg
      %Response{msg: msg, state: state} -> msg <> "\n" <> render_state(state)
    end
  end

  defp render_state(state) do
    headline = cond do
      state.won -> ["YOU WIN!"]
      state.lost -> ["YOU LOSE"]
      true -> []
    end
    {rows, columns} = state.squares |> Enum.map(fn {position, _} -> position end) |> Enum.unzip
    lines = for i <- rows |> Enum.uniq |> Enum.sort do
      columns
        |> Enum.uniq
        |> Enum.sort
        |> Enum.map(&render_square(state.squares[{i, &1}]))
        |> Enum.join(" ")
    end
    Enum.join(headline ++ lines ++ [""], "\n")
  end

  defp render_square(sq) do
    case sq do
      :unknown -> "?"
      :flagged -> "@"
      :exploded -> "*"
      n -> to_string(n)
    end
  end

  @cont_regex ~r/c (\w+)/
  @sweep_regex ~r/s (\d+)\s+(\d+)/
  @flag_regex ~r/f (\d+)\s+(\d+)/

  defp parse(cmd) do
    cond do
      cmd == "n" ->
        :new
      String.match?(cmd, @cont_regex) ->
        [_, id] = Regex.run(@cont_regex, cmd)
        {:continue, id}
      String.match?(cmd, @sweep_regex) ->
        [_, i, j] = Regex.run(@sweep_regex, cmd)
        {:sweep, {String.to_integer(i), String.to_integer(j)}}
      String.match?(cmd, @flag_regex) ->
        [_, i, j] = Regex.run(@flag_regex, cmd)
        {:flag, {String.to_integer(i), String.to_integer(j)}}
      true ->
        {:unknown}
    end
  end

end
