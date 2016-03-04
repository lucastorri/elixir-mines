alias Mines.Square

defmodule SquareTest do
  use ExUnit.Case
  doctest Square

  test "starts not clicked" do
    assert !%Square{}.clicked
  end

  test "starts not flagged" do
    assert !%Square{}.flagged
  end

end
