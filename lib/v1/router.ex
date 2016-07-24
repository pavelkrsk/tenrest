defmodule Tenrest.V1.Router do
  @moduledoc false

  use Plug.Router
  alias Tenrest.Redis
  alias Tenrest.Redis.KV

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  get "/kv/:id" do
    {success, val} = case Redis.q(KV.get(id)) do
      :undefined  -> {false, nil}
      res         -> {true, res}
    end
    resp = Poison.encode!(%{"success" => success, "value" => val})
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, resp)
  end

  put "/kv/:id" do
    value = conn.body_params["value"]
    :ok = Redis.q(KV.set(id, value))
    send_resp(conn, 201, "")
  end

  delete "/kv/:id" do
    Redis.q(KV.del(id))
    send_resp(conn, 204, "")
  end

  match _, do: send_resp(conn, 404, "API V1. No found!")
end
