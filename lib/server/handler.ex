alias Mines.Server.Response
alias Mines.Game
alias Mines.GameAgent
alias Mines.GameRegistry

defmodule Mines.Server.Handler do
  use GenServer

  @id_chars Enum.to_list Stream.concat(?a..?z, ?0..?9)
  @no_agent :no_game_agent
  @no_ref :no_game_update_ref

  def start_link(push) do
    GenServer.start_link(__MODULE__, push)
  end

  def init(push) do
    {:ok, {push, @no_agent, @no_ref}}
  end

  def handle_cast(:new, {push, game_agent, update_ref}) do
    {new_game_agent, res} =
      case GameAgent.new(Game.from_atom(:small)) do
        {:ok, game_agent, game_state} ->
          game_id = register(game_agent)
          {game_agent, %Response{msg: "New game #{game_id} started", state: game_state}}
        {:error, _, _} ->
          {@no_agent, %Response{msg: "Could not start a new game"}}
      end
    push.(res)
    update_ref = change_game(game_agent, update_ref, new_game_agent)
    {:noreply, {push, new_game_agent, update_ref}}
  end

  def handle_cast({:continue, game_id}, {push, game_agent, update_ref}) do
    {new_game_agent, res} =
      case GameRegistry.get(game_id) do
        {:ok, game} ->
          {game, %Response{state: GameAgent.state(game)}}
        {:error, _} ->
          {@no_agent, %Response{msg: "Could not load game #{game_id}"}}
      end
    push.(res)
    update_ref = change_game(game_agent, update_ref, new_game_agent)
    {:noreply, {push, new_game_agent, update_ref}}
  end

  def handle_cast({:sweep, position}, state = {_, game_agent, _}) do
    GameAgent.sweep(game_agent, position)
    {:noreply, state}
  end

  def handle_cast({:flag, position}, state = {_, game_agent, _}) do
    GameAgent.flag_swap(game_agent, position)
    {:noreply, state}
  end

  def handle_cast(msg, state) do
    {:noreply, state}
  end

  def handle_info({:updated, game_agent}, state = {push, _, _}) do
    push.(%Response{state: GameAgent.state(game_agent)})
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def terminate(_reason, {push, game_agent, update_ref}) do
    change_game(game_agent, update_ref, @no_agent)
  end

  defp change_game(old_game_agent, old_game_ref, new_game_agent) do
    if old_game_agent != @no_agent,
      do: GameAgent.unfollow_updates(old_game_agent, old_game_ref)
    if new_game_agent != @no_agent,
      do: GameAgent.follow_updates(new_game_agent),
      else: @no_ref
  end

  defp register(game) do
    case GameRegistry.register(random_id, game) do
      {:ok, id} -> id
      {:error, _} -> register(game)
    end
  end

  defp random_id do
    to_string for _ <- 0..8, do: Enum.random(@id_chars)
  end

  def command(pusher, cmd) do
    GenServer.cast(pusher, cmd)
  end

end