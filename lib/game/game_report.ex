alias Mines.Square

defmodule Mines.GameReport do

  def report(game) do
    squares =
      for {position, sq} <- game.squares, into: %{} do
        square_state = case sq do
          %Square{clicked: true, mined: true} -> :exploded
          %Square{clicked: true} -> neighbouring_mines(game, sq.position)
          %Square{flagged: true} -> :flagged
          %Square{} -> :unknown
        end
        {position, square_state}
      end
    %{lost: game.lost, won: game.won, squares: squares}
  end

  def neighbouring_mines(game, {i, j}) do
    mined_neighbours =
      for x <- (i-1)..(i+1),
          y <- (j-1)..(j+1),
          !(x == i and y == j),
          sq = game.squares[{x,y}],
          !is_nil(sq),
          sq.mined,
          do: sq

    Enum.count(mined_neighbours)
  end

end
