defmodule Tenrest do
  use Application
  alias Tenrest.Redis

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    port = Application.get_env(:tenrest, :cowboy_port, 8080)

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Tenrest.Worker.start_link(arg1, arg2, arg3)
      # worker(Tenrest.Worker, [arg1, arg2, arg3]),
      :poolboy.child_spec(Redis.pool_name, Redis.poolboy_config, Redis.config),
      Plug.Adapters.Cowboy.child_spec(:http, Tenrest.Plug.Router, [], port: port),
      supervisor(Tenrest.Storage.Lock.Sup, []),
      worker(Tenrest.Storage.TTLManager, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tenrest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
