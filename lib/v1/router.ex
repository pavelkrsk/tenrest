defmodule Tenrest.V1.Router do
  @moduledoc false

  use Plug.Router

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  get "/kv/:id" do
    send_resp(conn, 200, "#{id}")
  end

  put "/kv/:id" do
    send_resp(conn, 201, "Uploaded #{id}")
  end

  delete "/kv/:id" do
    send_resp(conn, 201, "Deleted #{id}")
  end

  match _, do: send_resp(conn, 404, "Oops!")
end
