alias Mines.Game
alias Mines.GameReport
alias Mines.GameAgent.State

defmodule Mines.GameAgent do
  use GenServer

  def new(game) do
    {status, agent} = GenServer.start(__MODULE__, game)
    {status, agent, report(game)}
  end

  def init(game) do
    {:ok, %State{game: game}}
  end

  def handle_call(:get, _from, state) do
    {:reply, state.game, state}
  end

  def handle_call({:update, f}, _from, state = %State{game: game, listeners: listeners}) do
    new_game =
      try do
        new_game = f.(game)
        notify_all(listeners, self)
        new_game
      rescue
        _ -> game
      end
    {:reply, new_game, %{state | game: new_game}}
  end

  def handle_cast({:follow, listener}, state = %State{listeners: listeners}) do
    state = %{state | listeners: listeners |> MapSet.put(listener)}
    {:noreply, state}
  end

  def handle_cast({:unfollow, listener}, state = %State{listeners: listeners}) do
    state = %{state | listeners: listeners |> MapSet.delete(listener)}
    {:noreply, state}
  end

  def sweep(game_agent, position) do
    GenServer.call(game_agent, {:update, &Game.sweep(&1, position)})
      |> report
  end

  def flag_swap(game_agent, position) do
    GenServer.call(game_agent, {:update, &Game.flag_swap(&1, position)})
      |> report
  end

  def state(game_agent) do
    GenServer.call(game_agent, :get)
      |> report
  end

  def stop(game_agent) do
    GenServer.stop(game_agent)
  end

  def follow_updates(game_agent, listener \\ self) do
    GenServer.cast(game_agent, {:follow, listener})
  end

  def unfollow_updates(game_agent, listener \\ self) do
    GenServer.cast(game_agent, {:unfollow, listener})
  end

  defp report(game) do
    GameReport.report(game)
  end

  defp notify_all(listeners, game_agent) do
    spawn(fn ->
      Enum.each(listeners, fn l ->
        try do
          send l, game_agent
        rescue
          _ -> {}
        end
      end)
    end)
  end

end
