alias Mines.Square

defmodule Mines.Game do

  defstruct won: false, lost: false, squares: %{}

  def from_atom(repr) do
    {size, mines} = case repr do
      :small -> {8, 8}
      :medium -> {16, 32}
      :large -> {32, 128}
    end

    positions = square_positions(size)
    with_mines = random_mines(positions, mines)

    squares =
      for position <- positions, do: %Square{position: position, mined: Enum.member?(with_mines, position)}

    from_squares(squares)
  end

  def from_squares(squares) do
    map = for square <- squares, into: %{}, do: {square.position, square}
    %Mines.Game{won: false, lost: false, squares: map}
  end

  def flag_swap(game, position) do
    square = game.squares[position]
    square = %{square | flagged: !square.flagged}
    squares = %{game.squares | position => square}
    %{game | squares: squares}
  end

  def sweep(game = %Mines.Game{lost: true}, _) do
    game
  end

  def sweep(game = %Mines.Game{won: true}, _) do
    game
  end

  def sweep(game, position) do
    square = %{game.squares[position] | clicked: true}
    squares = %{game.squares | position => square}
    %{game | squares: squares, lost: square.mined, won: won(squares)}
  end

  def finished(game) do
    game.lost or game.won
  end

  defp square_positions(size) do
    for i <- 0..(size-1), j <- 0..(size-1), do: {i, j}
  end

  defp random_mines(square_positions, total) do
    MapSet.new(Enum.take_random(square_positions, total))
  end

  defp won(squares) do
    squares
      |> Map.values
      |> Enum.filter(fn sq -> !sq.mined end)
      |> Enum.all?(fn sq -> sq.clicked end)
  end

end
