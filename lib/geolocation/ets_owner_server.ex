defmodule Geolocation.EtsOwnerServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(state) do
    :ets.new(:ip, [:named_table, :set, :private])
    :ets.insert(:ip, {:counter, 0})
    {:ok, state}
  end

  def handle_call({:insert_ip, ip, value}, _from, state) do
    :ets.insert(:ip, {ip, value})
    {:reply, :ok, state}
  end

  def handle_call(:incr_rejected, _from, state) do
    reply = :ets.update_counter(:ip, :counter, {2, 1})
    {:reply, reply, state}
  end

  def handle_call({:lookup_ip, ip}, _from, state) do
    reply = :ets.lookup(:ip, ip)
    {:reply, reply, state}
  end

  def handle_call(:get_rejected_count, _from, state) do
    [{_reply, count}] = :ets.lookup(:ip, :counter)
    {:reply, count, state}
  end
end
