alias Mines.Game
alias Mines.GameReport

defmodule GameReportTest do
  use ExUnit.Case
  doctest GameReport

  test "reports a new game report" do
    game = GameTest.tiny_game

    report = GameReport.report(game)

    assert report == %{
      won: false,
      lost: false,
      squares: %{
        {0, 0} => :unknown,
        {0, 1} => :unknown,
        {1, 0} => :unknown,
        {1, 1} => :unknown
      }
    }
  end

  test "reports a won game report" do
    game = GameTest.tiny_game
      |> Game.sweep({0, 1})
      |> Game.flag_swap({1, 1})
      |> Game.sweep({1, 0})

    report = GameReport.report(game)

    assert report == %{
      won: true,
      lost: false,
      squares: %{
        {0, 0} => :unknown,
        {0, 1} => 2,
        {1, 0} => 2,
        {1, 1} => :flagged
      }
    }
  end

  test "reports a lost game report" do
    game = GameTest.tiny_game
      |> Game.sweep({0, 1})
      |> Game.flag_swap({1, 1})
      |> Game.sweep({0, 0})

    report = GameReport.report(game)

    assert report == %{
      won: false,
      lost: true,
      squares: %{
        {0, 0} => :exploded,
        {0, 1} => 2,
        {1, 0} => :unknown,
        {1, 1} => :flagged
      }
    }
  end

end