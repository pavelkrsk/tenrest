defmodule V2RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Tenrest.Plug.Router

  @opts Router.init([])

  test "get" do
    conn = 
      conn(:get, "/kv/foo", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end


  test "returns 404" do
    conn = 
      conn(:get, "/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end


  test "put" do
    conn = 
      conn(:put, "/kv/foo", [value: "bar", ttl: "10"])
      |> put_req_header("accept-version", "2.0")
      |> Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 201
  end
  

  test "put get" do
    conn = 
      conn(:put, "/kv/foo4", [value: "barrr", ttl: "10"])
      |> put_req_header("accept-version", "2.0")
      |> Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 201

    conn = 
      conn(:get, "/kv/foo4", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "{\"value\":\"barrr\",\"success\":true}"
  end
  

  test "put get ttl" do
    conn(:delete, "/kv/foo5", "") |> Router.call(@opts)

    conn = 
      conn(:get, "/kv/foo5", "")
      |> Router.call(@opts)
   
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "{\"value\":null,\"success\":false}"
    
    # put
    conn = 
      conn(:put, "/kv/foo4", [value: "barrr", ttl: "1"])
      |> put_req_header("accept-version", "2.0")
      |> Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 201

    conn = 
      conn(:get, "/kv/foo4", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "{\"value\":\"barrr\",\"success\":true}"
    
    :timer.sleep(1010)

    conn = 
      conn(:get, "/kv/foo4", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "{\"value\":null,\"success\":false}"
  end


  test "delete" do
    conn = 
      conn(:delete, "/kv/foo", "")
      |> Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 204
  end
end

