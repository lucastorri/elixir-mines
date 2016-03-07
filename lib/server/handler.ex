defmodule Mines.Server.Handler do

  defmacro __using__(_) do
    quote do

      alias Mines.Game
      alias Mines.GameAgent
      alias Mines.GameRegistry
      alias Mines.Server.Response

      @id_chars Stream.concat(?a..?z, ?0..?9) |> Enum.to_list

      defp exec(cmd, current_game)

      defp exec({:new}, _) do
        case GameAgent.start(Game.from_atom(:small)) do
          {:ok, game, state} ->
            game_id = register(game)
            {game, %Response{msg: "New game #{game_id} started", state: state}}
          {:error, _, _} ->
            {nil, %Response{msg: "Could not start a new game"}}
        end
      end

      defp exec({:continue, game_id}, _) do
        case GameRegistry.get(game_id) do
          {:ok, game} ->
            {game, %Response{state: GameAgent.state(game)}}
          {:error, _} ->
            {nil, %Response{msg: "Could not load game #{game_id}"}}
        end
      end

      defp exec({:sweep, position}, current_game) do
        state = GameAgent.sweep(current_game, position)
        {current_game, %Response{state: state}}
      end

      defp exec({:flag, position}, current_game) do
        state = GameAgent.flag_swap(current_game, position)
        {current_game, %Response{state: state}}
      end

      defp exec(_, current_game) do
        {current_game, %Response{msg: "Unknown command"}}
      end

      defp register(game) do
        case GameRegistry.register(random_id, game) do
          {:ok, id} -> id
          {:error, _} -> register(game)
        end
      end

      defp random_id do
        to_string for _ <- 0..8, do: Enum.random(@id_chars)
      end

    end
  end

end
