alias Mines.Game
alias Mines.GameReport

defmodule Mines.GameAgent do

  def start(game) do
    {status, agent} = Agent.start(fn -> game end)
    {status, agent, report(game)}
  end

  def sweep(game_agent, position) do
    update(game_agent, fn game ->
      Game.sweep(game, position)
    end)
  end

  def flag_swap(game_agent, position) do
    update(game_agent, fn game ->
      Game.flag_swap(game, position)
    end)
  end

  def state(game_agent) do
    Agent.get(game_agent, fn game -> report(game) end)
  end

  def stop(game_agent) do
    Agent.stop(game_agent)
  end

  defp report(game) do
    GameReport.report(game)
  end

  defp update(game_agent, fun) do
    Agent.get_and_update(game_agent, fn game ->
      new_game = fun.(game)
      {report(new_game), new_game}
    end)
  end

end
