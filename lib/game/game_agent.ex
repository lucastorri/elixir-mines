alias Mines.Game
alias Mines.GameReport

defmodule Mines.GameAgent do

  def start(game) do
    {status, agent} = Agent.start_link(fn -> game end)
    {status, agent, report(game)}
  end

  def sweep(game_agent, position) do
    Agent.get_and_update(game_agent, fn game ->
      ng = Game.sweep(game, position)
      {report(ng), ng}
    end)
  end

  def flag_swap(game_agent, position) do
    Agent.get_and_update(game_agent, fn game ->
      ng = Game.flag_swap(game, position)
      {report(ng), ng}
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

end
