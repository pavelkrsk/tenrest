defmodule Tenrest.Plug.Router do
  @moduledoc false

  use Plug.Router

  @default_version "1.0"
  @versions %{
    "1.0" => Tenrest.V1.Router, 
    "2.0" => Tenrest.V2.Router
  } 


  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  match "/kv/:_key" do
    api_version = 
      conn
      |> get_req_header("accept-version")
      |> List.first()

    router =
      api_version
      |> checked_version
      |> version_handler

    router.call(conn, router.init([])) 
  end
  
  match _ do
    send_resp(conn, 404, "Not found.")
  end

  defp checked_version(nil), do: @default_version
  defp checked_version(version), do: version 

  defp version_handler(version) do
    case @versions[version] do
      nil     -> @versions[@default_version]
      handler -> handler
    end
  end
end

