defmodule Tenrest.V1.Router do
  @moduledoc false

  use Plug.Router
  alias Tenrest.Storage

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  get "/kv/:id" do
    {success, val} = case Storage.get(id) do
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
    :ok = Storage.set(id, value)
    send_resp(conn, 201, "")
  end

  delete "/kv/:id" do
    Storage.del(id)
    send_resp(conn, 204, "")
  end

  match _, do: send_resp(conn, 404, "API V1. Not found.")
end
