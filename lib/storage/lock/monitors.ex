defmodule Tenrest.Storage.Lock.Monitors do
  @moduledoc false

  defmodule MonitoringProcess do
    @type t :: %__MODULE__{
      count:      non_neg_integer,
      monitor:    reference,
      lock_refs:  [reference]
    }
    defstruct count: 0, monitor: nil, lock_refs: []
  end

  def new, do: Map.new

  def add_ref(processes, pid, ref) do
    new_process = case Map.fetch(processes, pid) do
      :error          -> create_monitor(pid, ref) 
      {:ok, process}  -> inc_lock_ref(process, ref)
    end
    Map.put(processes, pid, new_process)
  end


  def dec_ref(processes, pid, ref) do
    case Map.fetch(processes, pid) do
      :error -> 
        processes
      {:ok, process} ->
        if ref_in_process?(process, ref) do
          if single_ref?(process) do
            del_monitor(processes, process, pid)
          else
            dec_lock_ref(processes, process, pid, ref)
          end
        else
          processes
        end
    end
  end


  def remove(processes, pid) do
    case Map.fetch(processes, pid) do
      :error ->
        processes
      {:ok, %MonitoringProcess{monitor: monitor}} ->
        Process.demonitor(monitor)
        Map.delete(processes, pid)
    end
  end


  defp create_monitor(pid, ref) do
    %MonitoringProcess{
      count:      1, 
      monitor:    Process.monitor(pid),
      lock_refs:  Enum.into([ref], MapSet.new)
    }
  end

  defp inc_lock_ref(process, ref) do
    %MonitoringProcess{process | 
     count: process.count + 1, 
     lock_refs: MapSet.put(process.lock_refs, ref)
   }
  end


  defp dec_lock_ref(processes, process, pid, ref) do
    upd_process = %MonitoringProcess{
      process | 
      count: process.count - 1, 
      lock_refs: MapSet.delete(process.lock_refs, ref)}
    Map.put(processes, pid, upd_process) 
  end

  defp del_monitor(processes, %MonitoringProcess{monitor: monitor}, pid) do
    Process.demonitor(monitor)
    Map.delete(processes, pid)
  end


  defp ref_in_process?(process, ref), do: MapSet.member?(process.lock_refs, ref) 

  defp single_ref?(%MonitoringProcess{count: 1}), do: true
  defp single_ref?(%MonitoringProcess{}), do: false

end
