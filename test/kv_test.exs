defmodule KVTest do
  use ExUnit.Case

  alias Tenrest.Redis.KV
  alias Tenrest.Redis

  setup_all do
    Supervisor.terminate_child(Tenrest.Supervisor, Tentest.Plug.Router)

    {:ok, []}
  end
  
  setup state do
    state
  end

  test "set get", _state do
    key = "testkey"
    Redis.q(KV.set(key, "value"))
    Redis.q(KV.set(key, "value1"))

    assert Redis.q(KV.get(key)) == "value1"
  end

  test "setex", _state do
    key = "expkey"
    Redis.q(KV.setex(key, 1, "value1"))
    assert Redis.q(KV.get(key)) == "value1"
    :timer.sleep(1200)
    assert Redis.q(KV.get(key)) == :undefined
  end
  
  test "psetex", _state do
    key = "pexpkey"
    Redis.q(KV.psetex(key, 100, "value2"))
    assert Redis.q(KV.get(key)) == "value2"
    :timer.sleep(150)
    assert Redis.q(KV.get(key)) == :undefined
  end

  test "del get", _state do
    key = "somekey"
    Redis.q(KV.del(key))

    assert Redis.q(KV.get(key)) == :undefined
  end
end
