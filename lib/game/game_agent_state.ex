defmodule Mines.GameAgent.State do

  defstruct game: nil, listeners: MapSet.new, last_update: 0

end
