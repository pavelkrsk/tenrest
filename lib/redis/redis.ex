defmodule Tenrest.Redis do
  @moduledoc false

  @pool_name :redis_pool

  def pool_name(), do: @pool_name

  def poolboy_config do
    [{:name, {:local, @pool_name}},
     {:worker_module, Tenrest.Redis.Worker},
     {:size, 10},
     {:max_overflow, 1}]
  end
  
  def config do
    host      = Application.get_env(:exredis, :host)
    port      = Application.get_env(:exredis, :port)
    password  = Application.get_env(:exredis, :password)
    db        = Application.get_env(:exredis, :db)
    [host, port, password, db]
  end

  def q(fun) do
    w = :poolboy.checkout(@pool_name)
    result = w |> Tenrest.Redis.Worker.q(fun)
    :poolboy.checkin(@pool_name, w)
    result
  end
end
