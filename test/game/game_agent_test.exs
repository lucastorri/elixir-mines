alias Mines.Game
alias Mines.GameAgent
alias Mines.GameReport

defmodule GameAgentTest do
  use ExUnit.Case, async: false
  doctest GameAgent
  import Mock

  setup do
    game = GameTest.tiny_game
    {:ok, game: game}
  end

  test "starts with a given game", context do
    game = context[:game]

    {:ok, agent, state} = GameAgent.start(game)

    assert is_pid(agent)
    assert state == GameReport.report(game)
  end

  test "sweeps given positions", context do
    game = context[:game]
    {:ok, agent, _} = GameAgent.start(game)

    state = GameAgent.sweep(agent, {0, 1})

    assert state == GameReport.report(Game.sweep(game, {0, 1}))
  end

  test "exceptions should not change the current state", context do
    game = context[:game]
    {:ok, agent, _} = GameAgent.start(game)

    mocked_game = [sweep: fn(^game, {0, 1}) -> :meck.exception(:error, :invalid) end]
    with_mock Game, mocked_game do
      state = GameAgent.sweep(agent, {0, 1})

      assert called Game.sweep(game, {0, 1})
      assert state == GameReport.report(game)
    end

  end

end
