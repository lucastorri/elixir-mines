alias Mines.Server.Http

defmodule Mines.Server.Http.Supervisor do
  use Supervisor
  @behaviour Mines.Server.Supervisor

  @defaults [port: 8080]

  def start_link do
    start_link([])
  end

  def start_link(arg = {_, _}) do
    start_link([arg])
  end

  def start_link(args) do
    args = Keyword.merge(@defaults, is_list(args) && args || [])
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    children = [
      worker(Http, [args[:port]], restart: :permanent)
    ]
    supervise(children, strategy: :one_for_one)
  end

end

defmodule Mines.Server.Http do
  @behaviour(:cowboy_http_handler)
  @behaviour(:cowboy_websocket_handler)

  def start_link(port) do
    dispatch = :cowboy_router.compile([
      _: [
        {"/", :cowboy_static, {:priv_file, :mines, "index.html"}},
        {"/js/main.js", :cowboy_static, {:priv_file, :mines, "main.js"}},
        {"/websocket", __MODULE__, []}
      ]
    ])
    :cowboy.start_http(:http, 100, [port: port], env: [{:dispatch, dispatch}])
  end

  def init({:tcp, :http}, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def handle(_req, state) do
    {:ok, reply} = :cowboy_http_req.reply(404)
    {:ok, reply, state}
  end

  def websocket_init(_transport_name, req, _opts) do
    me = self
    {:ok, handler} = Mines.Server.Handler.start_link(fn res ->
      send me, {:res, render(res)}
    end)
    {:ok, req, handler}
  end

  def websocket_handle({:text, msg}, req, handler) do
    cmd = parse(msg)
    Mines.Server.Handler.command(handler, cmd)
    {:ok, req, handler}
  end

  def websocket_handle(_any, req, state) do
    {:reply, {:text, "unknown message"}, req, state, :hibernate}
  end

  def websocket_info({:timeout, _ref, msg}, req, state) do
    {:reply, {:text, msg}, req, state}
  end

  def websocket_info({:res, res}, req, state) do
    {:reply, {:text, res}, req, state}
  end

  def websocket_info(_info, req, state) do
    {:ok, req, state, :hibernate}
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  @cont_regex ~r/c (\w+)/
  @sweep_regex ~r/s (\d+)\s+(\d+)/
  @flag_regex ~r/f (\d+)\s+(\d+)/

  defp parse(cmd) do
    cond do
      cmd == "n" ->
        :new
      String.match?(cmd, @cont_regex) ->
        [_, id] = Regex.run(@cont_regex, cmd)
        {:continue, id}
      String.match?(cmd, @sweep_regex) ->
        [_, i, j] = Regex.run(@sweep_regex, cmd)
        {:sweep, {String.to_integer(i), String.to_integer(j)}}
      String.match?(cmd, @flag_regex) ->
        [_, i, j] = Regex.run(@flag_regex, cmd)
        {:flag, {String.to_integer(i), String.to_integer(j)}}
      true ->
        {:unknown}
    end
  end

  defp render(response) do
    response =
      if response.state do
        update_in(response.state.squares,
          &(Enum.to_list(&1) |> Enum.map(fn {{i,j}, v} -> [i, j, v] end)))
      else
        response
      end


    ExJSON.generate(response |> Map.from_struct)
  end

end
