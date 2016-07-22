defmodule Tenrest.Plug.Router do
  use Plug.Router

  #  alias Example.Plug.VerifyRequest
  
  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  get "/kv/:id" do
    send_resp(conn, 200, "#{id}\n")
  end

  put "/kv/:id" do
    send_resp(conn, 201, "Uploaded #{id}\n")
  end

  delete "/kv/:id" do
    send_resp(conn, 201, "Deleted #{id}\n")
  end

  match _, do: send_resp(conn, 404, "Oops!")

  end

