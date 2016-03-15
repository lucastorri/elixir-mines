alias Mines.Game
alias Mines.GameReport
alias Mines.GameAgent.State
alias Mines.GameAgent.EventHandler

defmodule Mines.GameAgent.State do

  defstruct game: nil, events: nil, last_update: System.system_time

end

defmodule Mines.GameAgent.EventHandler do
  use GenEvent

  def init([game_agent, listener]) do
    :erlang.monitor(:process, listener)
    {:ok, {game_agent, listener}}
  end

  def handle_event(event, state = {game_agent, listener}) do
    try do
      send listener, {event, game_agent}
    rescue
      _ -> {}
    end
    {:ok, state}
  end

  def handle_info({:DOWN, _, _, pid, _}, {_, listener}) when pid == listener do
    :remove_handler
  end

  def handle_info(_, state) do
    {:ok, state}
  end

end

defmodule Mines.GameAgent do
  use GenServer

  def new(game) do
    {status, agent} = GenServer.start(__MODULE__, game)
    {status, agent, report(game)}
  end

  def init(game) do
    with {:ok, events} = GenEvent.start_link(),
      do: {:ok, %State{game: game, events: events}}
  end

  def handle_call(:get, _from, state) do
    {:reply, state.game, state}
  end

  def handle_call({:update, f}, _from, state = %State{game: game, events: events}) do
    new_game =
      try do
        new_game = f.(game)
        notify_all(state, :updated)
        new_game
      rescue
        _ -> game
      end
    new_state = %{state | game: new_game, last_update: System.system_time}
    {:reply, new_game, new_state}
  end

  def handle_call({:follow, listener}, _from, state = %State{events: events}) do
    handler_ref = make_ref
    GenEvent.add_mon_handler(events, {EventHandler, handler_ref}, [self, listener])
    {:reply, handler_ref, state}
  end

  def handle_cast({:unfollow, handler_ref}, state = %State{events: events}) do
    GenEvent.remove_handler(events, {EventHandler, handler_ref}, [])
    {:noreply, state}
  end

  def terminate(_reason, state) do
    notify_all(state, :closing)
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
    GenServer.call(game_agent, {:follow, listener})
  end

  def unfollow_updates(game_agent, handler_ref) do
    GenServer.cast(game_agent, {:unfollow, handler_ref})
  end

  defp report(game) do
    GameReport.report(game)
  end

  defp notify_all(state, event) do
    GenEvent.notify(state.events, event)
  end

end
