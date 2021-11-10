defmodule Geolocation.Parse do
  alias Geolocation.EtsOwnerServer
  alias Geolocation.Schema.GeoData

  require Logger

  @moduledoc """
  Geolocation keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  alias NimbleCSV.RFC4180

  def init_parse() do
    GenServer.call(EtsOwnerServer, :reset)
    {time, _} = :timer.tc(&parse_csv/0)
    rejected = GenServer.call(EtsOwnerServer, :get_rejected_count)
    accepted = GenServer.call(EtsOwnerServer, :get_accepted_count)
    total = accepted + rejected

    Logger.info(
      "Time taken to parse #{time / 1_000_000} seconds \n Total: #{total} \n Rejected: #{rejected} \n Accepted: #{accepted}"
    )
  end

  def parse_csv() do
    window = Flow.Window.count(2000)
    path = Application.fetch_env!(:geolocation, :csv_path)

    path
    |> File.stream!()
    |> RFC4180.parse_stream()
    |> Flow.from_enumerable(window: window)
    |> filter_ips()
    |> create_structs()
    |> remove_nil_rows()
    |> combine_results()
  end

  defp filter_ips(flow) do
    flow
    |> Flow.filter(fn [h1 | _tail] ->
      val = :inet.parse_address(to_charlist(h1))
      if val == {:error, :einval}, do: GenServer.call(EtsOwnerServer, :incr_rejected)
      val != {:error, :einval}
    end)
  end

  defp create_structs(flow) do
    flow
    |> Flow.map(fn data ->
      data = convert_empty_to_nil(data)
      [ip, cc, cou, city, lat, long, mys] = data

      case GenServer.call(EtsOwnerServer, {:lookup_ip, ip}) do
        [{^ip, _}] ->
          GenServer.call(EtsOwnerServer, :incr_rejected)
          nil

        [] ->
          GenServer.call(EtsOwnerServer, {:insert_ip, ip, 0})
          GenServer.call(EtsOwnerServer, :incr_accepted)

          %{
            id: Ecto.UUID.generate(),
            ip_address: ip,
            country_code: cc,
            country: cou,
            city: city,
            latitude: parse_decimal(lat),
            longitude: parse_decimal(long),
            mystery_value: mys,
            inserted_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now()
          }
      end
    end)
  end

  defp remove_nil_rows(flow) do
    Flow.filter(flow, fn x -> not is_nil(x) end)
  end

  defp combine_results(flow) do
    flow
    |> Flow.reduce(fn -> [] end, fn event, acc -> [event | acc] end)
    |> Flow.on_trigger(fn x ->
      Geolocation.Repo.insert_all(GeoData, x)

      {[Enum.count(x)], x}
    end)
    |> Enum.to_list()
  end

  defp parse_decimal(nil) do
    nil
  end

  defp parse_decimal(val) do
    case Decimal.parse(val) do
      {val, _} ->
        val

      _ ->
        nil
    end
  end

  defp convert_empty_to_nil(lst) do
    Enum.map(lst, fn x ->
      if String.trim(x) == "", do: nil, else: x
    end)
  end
end
