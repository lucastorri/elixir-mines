defmodule Mines.Server.Supervisor do

  @callback start_link([{atom, any}]) :: {:ok, pid} | {:error, any}

end
