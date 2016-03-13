alias Mines.Server.Http

defmodule Mines.Server.Http.Supervisor do
  use Supervisor
  @behaviour Mines.Server.Supervisor

  @defaults [port: 8080]

  def start_link do
    start_link([])
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

  def websocket_info(info, req, state) do
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
        squares_as_lists =
          Enum.to_list(response.state.squares) |> Enum.map(fn {{i,j}, v} -> [i, j, v] end)
        %{response | state: %{response.state | squares: squares_as_lists}}
      else
        response
      end

    ExJSON.generate(response |> Map.delete(:__struct__))
  end

end

# defmodule Mines.Server.Http do
#   use Cauldron
#   use Mines.Server.Handler

#   def start_link(port) do
#     Cauldron.start_link(__MODULE__, port: port)
#   end

#   def handle("GET", %URI{path: "/"}, req) do
#     req |> Request.reply(200, html)
#   end

#   def handle("GET", %URI{path: "/game/" <> _game_id}, req) do
#     req |> Request.reply(200, html)
#   end

#   def handle("GET", %URI{path: "/api/new"}, req) do
#     {_, res} = exec({:new}, nil)
#     reply(req, res)
#   end

#   def handle("GET", %URI{path: "/api/sweep/" <> command}, req) do
#     exec_command(req, :sweep, command)
#   end

#   def handle("GET", %URI{path: "/api/flag/" <> command}, req) do
#     exec_command(req, :flag, command)
#   end

#   def missing(_, _, req) do
#     req |> Request.reply(404)
#   end

#   defp html(body \\ "") do
#     """
#     <html>
#       <head>
#         <title>elixir-mines</title>
#       </head>
#       <body>#{body}</body>
#     </html>
#     """
#   end



# end

