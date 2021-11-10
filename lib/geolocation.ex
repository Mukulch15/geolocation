defmodule Geolocation do
  alias Geolocation.Repo
  alias Geolocation.Schema.GeoData

  import Ecto.Query

  @moduledoc """
  Geolocation keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  def get_deo_data(ip_address) do
    try do
      with true <- is_ip_valid?(to_charlist(ip_address)),
           query = GeoData |> select([g], g) |> where([g], g.ip_address == ^ip_address),
           [data] <- Repo.all(query) do
        %{
          ip_address: data.ip_address,
          city: data.city,
          country: data.country,
          country_code: data.country_code,
          latitude: data.latitude,
          longitude: data.longitude,
          mystery_value: data.mystery_value
        }
      else
        false -> :bad_request
        [] -> %{}
      end
    rescue
      _ -> :internal_server_error
    end
  end

  def is_ip_valid?(ip_address) do
    case :inet.parse_address(ip_address) do
      {:error, :einval} -> false
      {:ok, _ip} -> true
    end
  end
end
