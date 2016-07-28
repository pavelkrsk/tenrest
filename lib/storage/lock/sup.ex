defmodule Tenrest.Storage.Lock.Sup do
  use Supervisor
  alias Tenrest.Storage.TTLManager

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args)
  end

  #supervisor callback
  def init(_args) do
    children = Enum.map(1..size, &worker_spec/1)
    supervise(children, strategy: :one_for_one)
  end

   def exec(id, fun) do
     Tenrest.Storage.Lock.exec(lock_pid(id), id, fun)
   end


  defp worker_spec(index) do
    opts = [[], worker_alias(index)]
    worker(Tenrest.Storage.Lock, opts, id: worker_alias(index))
  end
  
  def worker_alias(index), do: :"tenrest_lock_worker#{index}"

  def lock_pid(id), do: Process.whereis(worker_alias(:erlang.phash2(id, size) + 1))

  defp size, do: TTLManager.size
end
