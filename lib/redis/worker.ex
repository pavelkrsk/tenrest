defmodule Tenrest.Redis.Worker do
  @moduledoc false

  use GenServer

  defmodule State do
    defstruct host: "127.0.0.1", port: 6379, password: "", db: 0, client: :nil
  end

  def start_link([host, port, password, db]) do
    GenServer.start_link(__MODULE__, [host, port, password, db], [])
  end


  def q(pid, q), do: GenServer.call(pid, {:query, q})

  def init([host, port, password, db]) do
    send self, :init
    {:ok, %State{host: host, port: port, password: password, db: db}}
  end


  def handle_call({:query, query_fn}, _from, %State{client: client} = state) do
    result = client |> query_fn.()
    {:reply, result, state}
  end

  def handle_info(:init, %State{host: host, port: port, password: password, db: db}) do
    client = Exredis.start_using_connection_string("redis://user:#{password}@#{host}:#{port}")
    Exredis.Api.select(client, db)
    {:noreply, %State{client: client}}
  end


  def terminate(_reason, %State{client: client}) do
    client |> Exredis.stop
  end
end

