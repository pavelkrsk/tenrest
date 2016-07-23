defmodule Tenrest.Redis.KV do
  @moduledoc false

  def get(key), do: &Exredis.Api.get(&1, key)

  def set(key, value), do: &Exredis.Api.set(&1, key, value)
  def setex(key, secs, value), do: &Exredis.Api.setex(&1, key, secs, value)
  def psetex(key, msecs, value), do: &Exredis.Api.psetex(&1, key, msecs, value)

  def del(key), do: &Exredis.Api.del(&1, key)
end
