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

    {:ok, agent, state} = GameAgent.new(game)

    assert is_pid(agent)
    assert state == GameReport.report(game)
  end

  test "sweeps given positions", context do
    game = context[:game]
    {:ok, agent, _} = GameAgent.new(game)

    state = GameAgent.sweep(agent, {0, 1})

    assert state == GameReport.report(Game.sweep(game, {0, 1}))
  end

  test "exceptions should not change the current state", context do
    game = context[:game]
    {:ok, agent, _} = GameAgent.new(game)

    mocked_game = [sweep: fn(^game, {0, 1}) -> :meck.exception(:error, :invalid) end]
    with_mock Game, mocked_game do
      state = GameAgent.sweep(agent, {0, 1})

      assert called Game.sweep(game, {0, 1})
      assert state == GameReport.report(game)
    end

  end

  test "notifies listeners of updates", context do
    game = context[:game]
    {:ok, agent, _} = GameAgent.new(game)

    GameAgent.follow_updates(agent)
    GameAgent.flag_swap(agent, {0, 1})
    notification_1 = wait_message

    GameAgent.unfollow_updates(agent)
    GameAgent.flag_swap(agent, {0, 1})
    notification_2 = wait_message

    GameAgent.follow_updates(agent)
    GameAgent.stop(agent)
    notification_3 = wait_message

    assert notification_1 == {:updated, agent}
    assert notification_2 == :timed_out
    assert notification_3 == {:closing, agent}
  end

  defp wait_message do
    receive do
      e -> e
    after
      10 -> :timed_out
    end
  end

end
