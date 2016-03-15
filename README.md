# Mines

**TODO: Add description**

## Running in multiple nodes

In one machine/shell run

```bash
iex --sname 1 -S mix
```

In a second, run:

```bash
MINES_MASTER="1@$HOST_OF_FIRST_NODE" MINES_TELNET=2223 MINES_HTTP=8081 iex --sname 2 -S mix
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add mines to your list of dependencies in `mix.exs`:

        def deps do
          [{:mines, "~> 0.0.1"}]
        end

  2. Ensure mines is started before your application:

        def application do
          [applications: [:mines]]
        end

