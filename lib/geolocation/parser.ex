defmodule Geolocation.Parse do
  alias Geolocation.EtsOwnerServer
  alias Geolocation.Schema.GeoData

  require Logger

  @moduledoc """
  This module consists of functions that handles parsing of the csv file. It uses flow to parallelize the parsing process
  and get most out of the available cores. At the end of parsing it gives you the time taken, rejected count and total count.

  1. The init_parse/0 function starts the parsing.
  2. parse_csv/0 sets the window count(for batching of csv rows) and creates a csv stream using nimble_csv library. Then it is
  fed to flow and afterwards to different functions for processing.
  3. filter_ips/1 functions takes the flow and filters out the ip addresses that are invalid. It also increments the counter for ip
  addresses that got rejected.
  4. create_structs/1 function takes the flow and converts the emty string values in each row into nil and creates a map for each row
  for batch inserts in the later stages.
  5. remove_nil_rows/1 function takes the flow and removes all the nil rows from the previous step.
  6. combine_results/1 consists of reduce function that takes a window of 2000 rows and converts them into a single list
  of 2000 entries and passes them into the Flow.on_trigger/2 which inserts them as a batch for performance.
  """
  alias NimbleCSV.RFC4180

  @doc """
   This function starts the parsing.
  """
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
