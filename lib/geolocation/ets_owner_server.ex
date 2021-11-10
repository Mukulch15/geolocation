defmodule Geolocation.EtsOwnerServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(state) do
    initialize_tables()
    {:ok, state}
  end

  def handle_call({:insert_ip, ip, value}, _from, state) do
    :ets.insert(:ip, {ip, value})
    {:reply, :ok, state}
  end

  def handle_call(:incr_rejected, _from, state) do
    reply = :ets.update_counter(:ip, :rejected_counter, {2, 1})
    {:reply, reply, state}
  end

  def handle_call(:incr_accepted, _from, state) do
    reply = :ets.update_counter(:ip, :accepted_counter, {2, 1})
    {:reply, reply, state}
  end

  def handle_call({:lookup_ip, ip}, _from, state) do
    reply = :ets.lookup(:ip, ip)
    {:reply, reply, state}
  end

  def handle_call(:get_rejected_count, _from, state) do
    [{_reply, count}] = :ets.lookup(:ip, :rejected_counter)
    {:reply, count, state}
  end

  def handle_call(:get_accepted_count, _from, state) do
    [{_reply, count}] = :ets.lookup(:ip, :accepted_counter)
    {:reply, count, state}
  end

  def handle_call(:reset, _from, state) do
    :ets.delete(:ip)
    initialize_tables()
    {:reply, :ok, state}
  end

  defp initialize_tables() do
    :ets.new(:ip, [:named_table, :set, :private])
    :ets.insert(:ip, {:rejected_counter, 0})
    :ets.insert(:ip, {:accepted_counter, 0})
  end
end
