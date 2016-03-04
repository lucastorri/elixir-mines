alias Mines.Game
alias Mines.GameReport

defmodule Mines.GameAgent do

  def start(game, report \\ &GameReport.report/1) do
    {status, agent} = Agent.start_link(fn -> {game, report} end)
    {status, agent, report.(game)}
  end

  def sweep(game_agent, position) do
    Agent.get_and_update(game_agent, fn {game, report} ->
      ng = Game.sweep(game, position)
      {report.(ng), {ng, report}}
    end)
  end

end
