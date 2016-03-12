
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
      worker(Mines.Server.Http, [args[:port]], restart: :permanent)
    ]
    supervise(children, strategy: :one_for_one)
  end

end

defmodule Mines.Server.Http do
  use Cauldron
  use Mines.Server.Handler

  def start_link(port) do
    Cauldron.start_link(__MODULE__, port: port)
  end

  def handle("GET", %URI{path: "/"}, req) do
    req |> Request.reply(200, html)
  end

  def handle("GET", %URI{path: "/game/" <> game_id}, req) do
    req |> Request.reply(200, html)
  end

  def handle("GET", %URI{path: "/api/new"}, req) do
    {_, res} = exec({:new}, nil)
    reply(req, res)
  end

  def handle("GET", %URI{path: "/api/sweep/" <> command}, req) do
    exec_command(req, :sweep, command)
  end

  def handle("GET", %URI{path: "/api/flag/" <> command}, req) do
    exec_command(req, :flag, command)
  end

  @command_regex ~r/(\w+),(\d+),(\d+)/

  defp parse(cmd) do
    cond do
      String.match?(cmd, @command_regex) ->
        [_, game_id, i, j] = Regex.run(@command_regex, cmd)
        {game_id, {String.to_integer(i), String.to_integer(j)}}
      true ->
        :unknown
    end
  end

  def missing(_, _, req) do
    req |> Request.reply(404)
  end

  defp html(body \\ "") do
    """
    <html>
      <head>
        <title>elixir-mines</title>
      </head>
      <body>#{body}</body>
    </html>
    """
  end

  defp reply(req, res) do
    req |> Request.reply(200, render(res))
  end

  defp exec_command(req, type, command) do
    {game_id, position} = parse(command)
    {game, _} = exec({:continue, game_id}, nil)
    {_, res} = exec({type, position}, game)
    reply(req, res)
  end

  defp render(response) do
    squares_as_lists =
      Enum.to_list(response.state.squares)
        |> Enum.map(fn {{i,j}, v} -> [i, j, v] end)
    response =
      %{response | state: %{response.state | squares: squares_as_lists}}
        |> Map.delete(:__struct__)
    ExJSON.generate(response)
  end

end

