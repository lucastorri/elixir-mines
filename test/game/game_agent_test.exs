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

  test "exceptions should not change the current state" do
    bad_game = %Game{squares: %{{0,1} => nil}}
    {:ok, agent, _} = GameAgent.start(bad_game)

    state = GameAgent.sweep(agent, {0, 1})

    assert state == bad_game
  end

end
