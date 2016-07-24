defmodule Tenrest.V2.Router do
  @moduledoc false

  use Plug.Router
  alias Tenrest.Redis
  alias Tenrest.Redis.KV

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  get "/kv/:key" do
    {success, val} = case Redis.q(KV.get(key)) do
      :undefined  -> {false, nil}
      res         -> {true, res}
    end

    resp = Poison.encode!(%{"success" => success, "value" => val})
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, resp)
  end

  put "/kv/:key" do
    value = conn.body_params["value"]
    ttl   = conn.body_params["ttl"]
    
    fun = case ttl do
      nil -> fn -> Redis.q(KV.set(key, value)) end
      _   -> fn -> Redis.q(KV.setex(key, ttl, value)) end
    end

    case fun.() do
      :ok ->
        send_resp(conn, 201, "")
      "ERR" <> _ = err ->
        resp = Poison.encode!(%{"success" => false, "error": err})
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, resp)
    end
  end

  delete "/kv/:key" do
    Redis.q(KV.del(key))
    send_resp(conn, 204, "")
  end

  match _, do: send_resp(conn, 404, "API V2. Not found.")
end
