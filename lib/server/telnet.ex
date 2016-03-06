alias Mines.GameRegistry

require Logger

defmodule Mines.Server.Telnet do
  use Mines.Server

  @tcp_options [:binary, packet: :line, active: false, reuseaddr: true]

  def start(args) do
    Logger.debug "starting telnet server with args #{inspect args}"
    port = is_list(args) && args[:port] || 9023
    with {:ok, socket} <- :gen_tcp.listen(port, @tcp_options),
      do: accept_connection(socket)
  end

  defp accept_connection(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, conn} ->
        Task.start(fn -> handle_connection(conn, nil) end)
        accept_connection(socket)
      {:error, _} ->
        :gen_tcp.close(socket)
    end
  end

  defp handle_connection(conn, game) do
    case :gen_tcp.recv(conn, 0) do
      {:ok, input} ->
        {game, response} =
          input
            |> String.strip
            |> parse
            |> run(game)

        reply(render(response), conn)
        handle_connection(conn, game)
      {:error, _} ->
        :gen_tcp.close(conn)
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
        {:new}
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
