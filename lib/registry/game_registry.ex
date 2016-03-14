defmodule Mines.GameRegistry do

  @delegate Mines.GameRegistry.Mnesia

  defdelegate register(game_id, game), to: @delegate
  defdelegate get(game_id), to: @delegate

end

defmodule Mines.GameRegistry.Mnesia do
  use GenServer

  alias :mnesia, as: Mnesia
  alias Mines.GameRegistry.Mnesia.NodeMonitor

  @table_name :mines_game_registry
  @remote_command_timeout 5000

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    NodeMonitor.start_link(&install_on/1)
  end

  def install do
    nodes = [node]
    with :ok <- Mnesia.create_schema(nodes),
         :ok <- Mnesia.start,
         {:atomic, :ok} <- create_table(nodes),
         do: :ok
  end

  def register(game_id, game) do
    result = Mnesia.transaction(fn ->
      Mnesia.write({@table_name, game_id, game})
    end)
    case result do
      {:atomic, :ok} -> {:ok, game_id}
      {:aborted, reason} -> {:error, reason}
    end
  end

  def get(game_id) do
    result = Mnesia.transaction(fn ->
      Mnesia.read({@table_name, game_id})
    end)
    case result do
      {:atomic, []} -> {:error, :game_not_available}
      {:atomic, [{@table_name, ^game_id, game}]} -> {:ok, game}
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp create_table(nodes) do
    Mnesia.create_table(@table_name,
      attributes: [:key, :val],
      ram_copies: nodes)
  end

  defp install_on(node) do
    exec_on node, fn ->
      :mnesia.start
    end
    Mnesia.change_config(:extra_db_nodes, [node])
    exec_on node, fn ->
      :mnesia.add_table_copy(@table_name, node, :ram_copies)
    end
  end

  defp exec_on(node, fun) do
    me = self
    Node.spawn node, fn ->
      fun.()
      send me, :done
    end
    receive do
      :done -> {}
    after
      @remote_command_timeout -> raise "timeout"
    end
  end

end

defmodule Mines.GameRegistry.Mnesia.NodeMonitor do
  use GenServer

  alias :net_kernel, as: NetKernel

  def start_link(action) do
    GenServer.start_link(__MODULE__, action)
  end

  def init(action) do
    NetKernel.monitor_nodes true
    {:ok, action}
  end

  def handle_info({:nodeup, node}, action) do
    action.(node)
    {:noreply, action}
  end

end
