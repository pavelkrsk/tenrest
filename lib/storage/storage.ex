defmodule Tenrest.Storage do
  @moduledoc false

  alias Tenrest.Storage.{Lock, KV, TTL, TTLManager, Lock.Sup}
  @milli 1000

  def set(key, value) do
    case KV.get(key) do
      :error ->
        do_set(key, value)
      {:ok, {_old_value, 0}} ->
        do_set(key, value)
      {:ok, {_old_value, ttl}} ->
        fun = fn ->
          del_ttl(key, ttl)
          KV.set(key, value)
        end
        Lock.exec(Sup.lock_pid(key), key, fun)
    end
  end

  def set(key, ttl, value) do
    expire_time = :erlang.system_time(:milli_seconds) + ttl * @milli

    case KV.get(key) do
      :error -> 
        do_set(key, expire_time, value)
      {:ok, {_value, 0}} ->
        do_set(key, expire_time, value)
      {:ok, {_value, old_ttl}} ->
        fun = fn ->
          del_ttl(key, old_ttl)
          KV.set(key, expire_time, value)
          set_ttl(key, expire_time)
        end
        Lock.exec(Sup.lock_pid(key), key, fun)
    end
  end


  def get(key) do
    now = :erlang.system_time(:milli_seconds)
    case KV.get(key) do
      :error -> 
        :undefined
      {:ok, {value, 0}} ->
        value
      {:ok, {value, ttl}} ->
        if ttl < now do
          :undefined
        else
          value
        end
    end
  end

  def del(key) do
    fun = fn ->
      case KV.get(key) do
        :error -> 
          :ok
        {:ok, {_value, ttl}} ->
          KV.del(key)
          del_ttl(key, ttl)
      end
    end
    Lock.exec(Sup.lock_pid(key), key, fun)
  end

  def del_only_val(key) do
    fun = fn -> KV.del(key) end
    Lock.exec(Sup.lock_pid(key), key, fun)
  end
  
  def set_ttl(id, ttl) do
    table = get_table_id(id)
    value = case TTL.get(table, ttl) do
      :error   -> [id]
      {:ok, l} -> [id | l]
    end
    TTL.set(table, ttl, value)
  end


  def del_ttl(id, ttl) do
    table = get_table_id(id)
    case TTL.get(table, ttl) do
      :error ->
        :ok
      {:ok, [^id]} ->
        TTL.del(table, ttl)
      {:ok, l} ->
        TTL.set(table, ttl, List.delete(l, id))
    end
  end

  defp do_set(key, value) do
    fun = fn -> KV.set(key, value) end
    Lock.exec(Sup.lock_pid(key), key, fun)
  end

  defp do_set(key, ttl, value) do
    fun = fn -> 
      KV.set(key, ttl, value)
      set_ttl(key, ttl)
    end
    Lock.exec(Sup.lock_pid(key), key, fun)
  end

  def get_table_id(id) do
    index = :erlang.phash2(id, TTLManager.size) + 1
    TTL.table_alias(index)
  end
end
