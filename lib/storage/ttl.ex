defmodule Tenrest.Storage.TTL do
  @moduledoc false

  @def_ttl 0

  def table_alias(index), do: :"tenrest_ttl_table#{index}"
  
  def init(index) do 
    :ets.new(table_alias(index), [:named_table, 
      :ordered_set,
      :public,
      {:keypos, 1}])
  end

  def first(table), do: :ets.first(table)
  def next(table, key), do: :ets.next(table, key)

  def get(table, key) do
    case :ets.lookup(table, key) do
      [{^key, value}] -> {:ok, value}
        _             -> :error
    end
  end

  def set(table, key, value), do: :ets.insert(table, {key, value})

  def del(table, key), do: :ets.delete(table, key) 
end
