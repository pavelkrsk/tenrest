defmodule Tenrest.Storage.KV do
  @moduledoc false
  
  @table_name :tenrest_storage_kv
  @default_ttl 0

  def init() do 
  :ets.new(@table_name, [:named_table, 
    :set, 
    :public, 
    {:keypos, 1}, 
    {:read_concurrency, true},
    {:write_concurrency, true} ])
  end

  def get(key) do
    case :ets.lookup(@table_name, key) do
      [{^key, value}] -> {:ok, value}
        _ -> :error
    end
  end

  def set(key, value), do: set(key, @default_ttl, value)
  def set(key, ttl, value), do: :ets.insert(@table_name, {key, {value, ttl}})

  def del(key), do: :ets.delete(@table_name, key) 

end
