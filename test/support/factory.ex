defmodule Geolocation.Factory do
  use ExMachina.Ecto, repo: Geolocation.Repo
  @moduledoc false
  def geo_data_factory(params) do
    %Geolocation.Schema.GeoData{
      ip_address: params.ip_address,
      country_code: params.country_code,
      country: params.country,
      city: params.city,
      latitude: params.latitude,
      longitude: params.longitude,
      mystery_value: params.mystery_value
    }
  end
end
