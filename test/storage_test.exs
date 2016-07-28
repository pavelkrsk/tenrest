defmodule StorageTest do
  @moduledoc false

  use ExUnit.Case
  alias Tenrest.Storage

  test "not exist" do
    assert Storage.get("foo") == :undefined
  end


  test "set get" do
    Storage.set("key1", "bar")
    assert Storage.get("key1") == "bar"
  end
  
  test "set ttl get" do
    Storage.set("key2", 1, "bar")
    assert Storage.get("key2") == "bar"
    :timer.sleep(1010)
    assert Storage.get("key2") == :undefined
  end

  test "concurrent set ttl get" do
    fun = fn i ->
      Storage.set("con_key#{i}", (rem(i,2) + 1) , "bar#{i}")
    end

    fun_get = fn i -> Storage.get("con_key#{i}") end


    1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000)) 

    :timer.sleep(1010) 

    res = 1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_get.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000))


    {undef, vals} = Enum.partition(res, fn(x) -> x == :undefined end)
    expected = Enum.map(:lists.seq(1,1000,2), &("bar#{&1}"))
    assert length(undef) == 500
    assert vals == expected
  end


  test "concurrent set ttl set" do
    fun_set_ttl = fn i ->
      Storage.set("con_set_key#{i}", (rem(i,2)) , "bar#{i}")
    end
    fun_set = fn i ->
      Storage.set("con_set_key#{i}", "barrr#{i}")
    end

    fun_get = fn i -> Storage.get("con_set_key#{i}") end


    1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_set_ttl.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000)) 
    
    1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_set.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000)) 

    :timer.sleep(1010) 

    res = 1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_get.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000))


    expected = Enum.map(1..1000, &("barrr#{&1}"))
    assert res == expected
  end
  
  test "concurrent set set ttl" do
    fun_set = fn i ->
      Storage.set("con_set_key#{i}", "barrr#{i}")
    end

    fun_set_ttl = fn i ->
      Storage.set("con_set_key#{i}", (rem(i,2)) , "bar#{i}")
    end

    fun_get = fn i -> Storage.get("con_set_key#{i}") end


    1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_set.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000)) 
    
    1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_set_ttl.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000)) 

    :timer.sleep(1010) 

    res = 1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_get.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000))


    expected = List.duplicate(:undefined, 1000)
    assert res == expected
  end

  test "concurrent set del" do
    fun_set = fn i ->
      Storage.set("con_del_key#{i}", "bar#{i}")
    end
    fun_del = fn i ->
      Storage.del("con_del_key#{i}")
    end

    fun_get = fn i -> Storage.get("con_del_key#{i}") end


    1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_set.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000)) 
    
    1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_del.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000)) 


    res = 1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_get.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000))


    expected = List.duplicate(:undefined, 1000) 
    assert res == expected
  end

  test "concurrent set ttl del" do
    fun_set_ttl = fn i ->
      Storage.set("con_del_key#{i}", (rem(i,2)) , "bar#{i}")
    end
    fun_del = fn i ->
      Storage.del("con_del_key#{i}")
    end

    fun_get = fn i -> Storage.get("con_del_key#{i}") end


    1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_set_ttl.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000)) 
    
    1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_del.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000)) 


    res = 1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_get.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000))


    expected = List.duplicate(:undefined, 1000) 
    assert res == expected
  end
  
  test "concurrent set partially delete" do
    fun = fn i ->
      Storage.set("con_part_del_key#{i}", (rem(i,2) + 1) , "bar#{i}")
    end

    fun_del = fn i -> if rem(i, 2) == 0 do Storage.del("con_part_del_key#{i}") end end

    fun_get = fn i -> Storage.get("con_part_del_key#{i}") end


    1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000)) 
    
    1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_del.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000)) 

    res = 1..1000
    |> Enum.map(fn i -> Task.async(fn -> fun_get.(i) end) end)
    |> Enum.map(&Task.await(&1, 1000))

    {undef, vals} = Enum.partition(res, fn(x) -> x == :undefined end)
    expected = Enum.map(:lists.seq(1,1000,2), &("bar#{&1}"))
    assert length(undef) == 500
    assert vals == expected
  end
end
