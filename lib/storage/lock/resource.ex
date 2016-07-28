defmodule Tenrest.Storage.Lock.Resource do
  @moduledoc false

  defstruct owner: nil,
            count: 0,
            owner_queue: :queue.new,
            values: Map.new,
            lock_refs: MapSet.new
        

  def new, do: %__MODULE__{}

  def owner(%__MODULE__{owner: owner}), do: owner

  def empty?(%__MODULE__{owner: nil, values: values}) do
    Map.size(values) == 0
  end
  def empty?(_), do: false


  def inc_lock(%__MODULE__{owner: pid} = resource, lock_ref, pid, value) do
    {{:acquired, value}, inc_ref(resource, lock_ref)}
  end

  def inc_lock(%__MODULE__{owner_queue: owner_queue, values: values, lock_refs: lock_refs} = resource, lock_ref, pid, value) do
    acquire_next(%__MODULE__{resource |
      owner_queue:  :queue.in(pid, owner_queue),
      values:       Map.put(values, pid, value),
      lock_refs:    MapSet.put(lock_refs, lock_ref)
    })
  end


  def dec_lock(%__MODULE__{lock_refs: lock_refs} = resource, lock_ref, pid) do
    if MapSet.member?(lock_refs, lock_ref) do
      %__MODULE__{resource | lock_refs: MapSet.delete(lock_refs, lock_ref)}
      |> dec_owner_lock(pid)
      |> release_pending(pid)
      |> acquire_next
    else
      {:not_acquired, resource}
    end
  end


  def remove_caller(resource, pid) do
    resource
    |> release_owner(pid)
    |> release_pending(pid)
    |> acquire_next
  end


  defp acquire_next(%__MODULE__{owner: nil, owner_queue: owner_queue, values: values} = resource) do
    case :queue.out(owner_queue) do
      {:empty, _} -> 
        {:not_acquired, resource}
      {{:value, pid}, owner_queue} ->
        {value, values} = Map.pop(values, pid)
        upd_resource = %__MODULE__{resource |
                                    owner: pid,
                                    count: 1,
                                    owner_queue: owner_queue,
                                    values: values}
        {{:acquired, value}, upd_resource}
    end
  end

  defp acquire_next(%__MODULE__{} = resource) do
    {:not_acquired, resource}
  end

  defp inc_ref(%__MODULE__{count: count, lock_refs: lock_refs} = resource, lock_ref) do
    %__MODULE__{resource | count: count + 1, lock_refs: MapSet.put(lock_refs, lock_ref)} 
  end

  defp dec_owner_lock(%__MODULE__{owner: pid, count: 1} = resource, pid) do
    %__MODULE__{resource | owner: nil, count: 0}
  end

  defp dec_owner_lock(%__MODULE__{owner: pid, count: count} = resource, pid) when count > 1 do
    %__MODULE__{resource | owner: pid, count: count - 1}
  end

  defp dec_owner_lock(resource, _) do
    resource
  end



  defp release_owner(%__MODULE__{owner: pid} = resource, pid) do
    %__MODULE__{resource | owner: nil, count: 0}
  end
  defp release_owner(resource, _) do
    resource
  end

  defp release_pending(resource, pid) do
    %__MODULE__{owner_queue: owner_queue, values: values} = resource
    if Map.has_key?(values, pid) do
      %__MODULE__{resource |
        owner_queue: :queue.filter(&(&1 !== pid), owner_queue),
        values: Map.delete(values, pid)
      }
    else
      resource
    end
  end
end
