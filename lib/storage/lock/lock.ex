defmodule Tenrest.Storage.Lock do
  @moduledoc false

  use GenServer
  alias Tenrest.Storage.Lock.Monitors
  alias Tenrest.Storage.Lock.Resource

  defmodule State do
    defstruct resources: Map.New, monitors: Monitors.new
  end

  def start_link(args, name) do
    GenServer.start_link(__MODULE__, args, name: name)
  end


  def exec(lock_server, id, fun) do
    lock_ref = make_ref
    try do
      # lock
      :acquired = GenServer.call(lock_server, {:lock, id, lock_ref})
      fun.()
    after
      # unlock
      GenServer.cast(lock_server, {:unlock, id, lock_ref, self})
    end
  end

  def init([]) do
    {:ok, %State{resources: Map.new, monitors: Monitors.new}}
  end

  def handle_call({:lock, id, lock_ref}, {caller_pid, _} = from, state) do
    %State{monitors: monitors, resources: resources} = state
    monitors      = Monitors.add_ref(monitors, caller_pid, lock_ref)

    resource      = resource(resources, id)
    chng_resource = Resource.inc_lock(resource, lock_ref, caller_pid, from)
    resources     = handle_resource_change(resources, id, chng_resource) 
    {:noreply, %State{state | monitors: monitors, resources: resources}}
  end 


  def handle_cast({:unlock, id, lock_ref, caller_pid}, state) do
    %State{monitors: monitors, resources: resources} = state
    monitors      = Monitors.dec_ref(monitors, caller_pid, lock_ref)

    resource      = resource(resources, id)
    chng_resource = Resource.dec_lock(resource, lock_ref, caller_pid)
    resources     = handle_resource_change(resources, id, chng_resource)
    {:noreply, %State{state | monitors: monitors, resources: resources}}
  end
  
  def handle_info({:DOWN, _, _, caller_pid, _}, %State{monitors: monitors, resources: resources} = state) do
    monitors  = Monitors.remove(monitors, caller_pid)
    resources = remove_caller_from_all_resources(resources, caller_pid)
    {:noreply, %State{state | monitors: monitors, resources: resources}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end


  defp handle_resource_change(resources, id, resource_change_result) do
    resource = maybe_notify_caller(resource_change_result)
    store_resource(resources, id, resource)
  end

  defp maybe_notify_caller({:not_acquired, resource}) do
    resource
  end
  defp maybe_notify_caller({{:acquired, from}, resource}) do
    if Process.alive?(Resource.owner(resource)) do
      GenServer.reply(from, :acquired)
      resource
    else
      remove_caller_from_resource(resource, Resource.owner(resource))
    end
  end

  defp remove_caller_from_resource(resource, caller_pid) do
    resource
    |> Resource.remove_caller(caller_pid)
    |> maybe_notify_caller
  end

  defp remove_caller_from_all_resources(resources, caller_pid) do
    Enum.reduce(resources, resources,
      fn({id, resource}, acc) ->
        store_resource(acc, id, remove_caller_from_resource(resource, caller_pid))
      end
    )
  end

  defp resource(resources, id) do
    case Map.fetch(resources, id) do
      {:ok, resource} -> resource
      :error          -> Resource.new
    end
  end

  defp store_resource(resources, id, resource) do
    if Resource.empty?(resource) do
      Map.delete(resources, id)
    else
      Map.put(resources, id, resource)
    end
  end
end
