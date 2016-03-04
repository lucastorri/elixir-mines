alias Mines.Game
alias Mines.GameAgent
alias Mines.GameReport

defmodule GameAgentTest do
  use ExUnit.Case
  doctest GameAgent

  test "starts with a given game" do
    game = GameTest.tiny_game

    {:ok, agent, state} = GameAgent.start(game)

    assert is_pid(agent)
    assert state == GameReport.report(game)
  end

  test "sweeps given positions" do
    game = GameTest.tiny_game
    {:ok, agent, _} = GameAgent.start(game)

    state = GameAgent.sweep(agent, {0, 1})

    assert state == GameReport.report(Game.sweep(game, {0, 1}))
  end

end
