defmodule Geolocation.Parse do
  alias Geolocation.Schema.GeoData

  @moduledoc """
  Geolocation keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  @path "/Users/mukul/Downloads/data_dump.csv"
  alias NimbleCSV.RFC4180
  # NimbleCSV.define(MyParser, separator: "\t", escape: "\"")
  def csv_module() do
    @path
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(num_workers: System.schedulers_online())
    |> Enum.to_list()
  end

  def nimble_csv() do
    @path
    |> File.stream!()
    |> RFC4180.parse_stream()
    |> Enum.map(fn [h1 | [h2 | _t]] -> h1 <> h2 end)
  end

  def nimble_csv_flow() do
    :ets.new(:test, [:named_table, :set, :public])
    :ets.new(:ip, [:named_table, :set, :public])
    window = Flow.Window.count(2000)

    @path
    |> File.stream!()
    |> RFC4180.parse_stream()
    |> Flow.from_enumerable(window: window)
    |> Flow.filter(fn [h1 | _tail] ->
      :inet.parse_address(to_charlist(h1)) != {:error, :einval}
    end)
    |> Flow.map(fn data ->
      data = Enum.map(data, fn x -> if x == "", do: nil, else: x end)
      [ip, cc, cou, city, lat, long, mys] = data

      case :ets.lookup(:ip, ip) do
        [{^ip, _}] ->
          :ets.update_counter(:test, "counter", {2, 1}, {"counter", 0})
          nil

        [] ->
          :ets.insert(:ip, {ip, 0})

          lat =
            case parse_decimal(lat) do
              {val, _} -> val
              _ -> Decimal.from_float(0.0)
            end

          long =
            case parse_decimal(long) do
              {val, _} -> val
              _ -> Decimal.from_float(0.0)
            end

          %{
            id: Ecto.UUID.generate(),
            ip_address: ip,
            country_code: cc,
            country: cou,
            city: city,
            latitude: lat,
            longitude: long,
            mystery_value: mys,
            inserted_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now()
          }
      end
    end)
    |> Flow.filter(fn x -> not is_nil(x) end)
    |> Flow.reduce(fn -> [] end, fn event, acc -> [event | acc] end)
    |> Flow.on_trigger(fn x ->
      Geolocation.Repo.insert_all(GeoData, x)

      {[Enum.count(x)], x}
    end)
    |> Enum.to_list()
  end

  def parse_decimal(nil) do
    {nil, ""}
  end

  def parse_decimal(val) do
    Decimal.parse(val)
  end
end
