# Mines

**TODO: Add description**

## Running on multiple nodes

In one machine/shell run:

```bash
iex --sname 1 -S mix
```

In a second:

```bash
MINES_MASTER="1@$(hostname -s)" MINES_TELNET=2223 MINES_HTTP=8081 iex --sname 2 -S mix
```
