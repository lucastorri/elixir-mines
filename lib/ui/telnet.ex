alias Mines.Game
alias Mines.GameAgent
alias Mines.GameRegistry

defmodule Mines.UI.Telnet do

  @options [:binary, packet: :line, active: false, reuseaddr: true]
  @id_chars 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

  def start(args) do
    port = is_list(args) && args[:port] || 9023
    case :gen_tcp.listen(port, @options) do
      {:ok, socket} -> accept_connection(socket)
      error -> error
    end
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
        {game, replies} =
          input
            |> String.strip
            |> parse
            |> run(game)

        replies |> Enum.each(&reply(&1, conn))
        handle_connection(conn, game)
      {:error, _} ->
        :gen_tcp.close(conn)
    end
  end

  defp reply(message, conn) do
    :gen_tcp.send(conn, message)
    :gen_tcp.send(conn, "\n")
  end

  defp run(cmd, current_game)

  defp run({:new}, _) do
    case GameAgent.start(Game.from_atom(:small)) do
      {:ok, game, state} ->
        game_id = register(game)
        {game, ["New game #{game_id} started", render(state)]}
      {:error, _, _} ->
        {nil, ["Could not start a new game"]}
    end
  end

  defp run({:continue, game_id}, _) do
    case GameRegistry.get(game_id) do
      {:ok, game} ->
        {game, [render(GameAgent.state(game))]}
      {:error, _} ->
        {nil, ["Could not load game #{game_id}"]}
    end
  end

  defp run({:sweep, position}, current_game) do
    state = GameAgent.sweep(current_game, position)
    {current_game, [render(state)]}
  end

  defp run({:flag, position}, current_game) do
    state = GameAgent.flag_swap(current_game, position)
    {current_game, [render(state)]}
  end

  defp run(_, current_game) do
    {current_game, ["Unknown command"]}
  end

  defp render(state) do
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
    Enum.join(headline ++ lines ++ ["\n"], "\n")
  end

  defp render_square(sq) do
    case sq do
      :unknown -> "?"
      :flagged -> "@"
      :exploded -> "*"
      n -> to_string(n)
    end
  end

  defp register(game) do
    case GameRegistry.register(random_id, game) do
      {:ok, id} -> id
      {:error, _} -> register(game)
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

  defp random_id do
    to_string for _ <- 0..8, do: Enum.random(@id_chars)
  end

end
