defmodule Tenrest.Storage.TTLManager do
  @moduledoc false

  use GenServer
  alias Tenrest.Storage.{KV, TTL}
  alias Tenrest.Storage

  @check_interval 1000

  defmodule State do
    defstruct timer: nil, table: nil
  end

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end


  def size, do: 128
  
  def init([]) do
    timer = :erlang.send_after(1, self, :init)
    {:ok, %State{timer: timer}}
  end

  def handle_info({:check, index}, %State{timer: timer} = state) do
    :erlang.cancel_timer(timer)
    timer = 
      index
      |> next_index(size)
      |> check_timer

    table = TTL.table_alias(index)
    {ttls, keys} = get_expired_keys(table, :erlang.system_time(:milli_seconds))
   
    keys |> Enum.each(&Storage.del(&1))
    ttls |> Enum.each(&TTL.del(table, &1))
    
    {:noreply, %State{state | timer: timer}}
  end

  def handle_info(:init, %State{timer: timer} = state) do
    :erlang.cancel_timer(timer)

    KV.init
    Enum.each(1..size, &TTL.init(&1))
    timer = check_timer(1) 
    {:noreply, %State{state | timer: timer}}
  end


  defp get_expired_keys(table, time) do
    do_get_expired_keys(table, time, 0, [], [])
  end

  defp do_get_expired_keys(table, time, ttl, ttls, keys) do
    case TTL.next(table, ttl) do
      :"$end_of_table" ->
        {ttls, keys}
      new_ttl ->
        if new_ttl < time do
          {:ok, curr_keys} = TTL.get(table, new_ttl)
          do_get_expired_keys(table, time, new_ttl, [new_ttl | ttls], curr_keys ++ keys)
        else
          {ttls, keys}
        end
    end
  end


  defp check_timer(index) do
    :erlang.send_after(@check_interval, self, {:check, index})
  end


  defp next_index(size, size), do: 1
  defp next_index(index, _size), do: index + 1

end
