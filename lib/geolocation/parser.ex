defmodule Geolocation.Parse do
  alias Geolocation.EtsOwnerServer
  alias Geolocation.Schema.GeoData

  @moduledoc """
  Geolocation keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  alias NimbleCSV.RFC4180

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
    window = Flow.Window.count(2000)
    path = Application.fetch_env!(:geolocation, :csv_path)

    path
    |> File.stream!()
    |> RFC4180.parse_stream()
    |> Flow.from_enumerable(window: window)
    |> Flow.filter(fn [h1 | _tail] ->
      val = :inet.parse_address(to_charlist(h1))
      if val == {:error, :einval}, do: GenServer.call(EtsOwnerServer, :incr_rejected)
      val != {:error, :einval}
    end)
    |> Flow.map(fn data ->
      data = Enum.map(data, fn x -> if x == "", do: nil, else: x end)
      [ip, cc, cou, city, lat, long, mys] = data

      case GenServer.call(EtsOwnerServer, {:lookup_ip, ip}) do
        [{^ip, _}] ->
          GenServer.call(EtsOwnerServer, :incr_rejected)
          nil

        [] ->
          GenServer.call(EtsOwnerServer, {:insert_ip, ip, 0})

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
