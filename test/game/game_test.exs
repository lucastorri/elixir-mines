alias Mines.Game
alias Mines.Square

defmodule GameTest do
  use ExUnit.Case
  doctest Game

  test "creates from atom" do
    import Game, only: [from_atom: 1]

    assert squares_and_mines(from_atom(:small)) == {64, 8}
    assert squares_and_mines(from_atom(:medium)) == {256, 32}
    assert squares_and_mines(from_atom(:large)) == {1024, 128}
  end

  test "returns same game if already lost" do
    lost_game = %{Game.from_atom(:small) | lost: true}

    assert Game.sweep(lost_game, {0, 0}) == lost_game
  end

  test "returns same game if already won" do
    won_game = %{Game.from_atom(:small) | won: true}

    assert Game.sweep(won_game, {0, 0}) == won_game
  end

  test "looses when sweeping a mined square" do
    game = tiny_game

    game = Game.sweep(game, {0, 0})

    assert game.lost and !game.won
    assert game.squares[{0, 0}].clicked
  end

  test "opens swept square" do
    game = tiny_game

    game = Game.sweep(game, {0, 1})

    assert !(game.lost or game.won)
    assert game.squares[{0, 1}].clicked
  end

  test "wins after sweeping all free squares" do
    game = tiny_game

    game = game |> Game.sweep({0, 1}) |> Game.sweep({1, 0})

    assert game.won and !game.lost
  end

  defp squares_and_mines(game) do
    {square_count(game), mines_count(game)}
  end

  defp square_count(game) do
    game.squares |> Enum.count
  end

  def mines_count(game) do
    game.squares |> Enum.filter(fn {_, sq} -> sq.mined end) |> Enum.count
  end

  defp tiny_game do
    squares = for i <- 0..1, j <- 0..1, do: %Square{position: {i, j}, mined: i==j}
    Game.from_squares(squares)
  end

end
