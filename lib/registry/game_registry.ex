defmodule Mines.GameRegistry do

  @table_name :games_registry

  def init do
    :ets.new(@table_name, [:named_table, :public])
  end

  def register(game_id, game) do
    if :ets.insert_new(@table_name, {game_id, game}) do
      {:ok, game_id}
    else
      {:error, :existing_id}
    end
  end

  def get(game_id) do
    case :ets.lookup(@table_name, game_id) do
      [] ->
        {:error, "Game #{game_id} not available"}
      [{^game_id, game}] ->
        {:ok, game}
    end
  end

end
