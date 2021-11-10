defmodule Geolocation.Schema.GeoData do
  @moduledoc """
   Schema for game
  """
  import Ecto.Changeset

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "geo_data" do
    field :ip_address, :string
    field :country_code, :string
    field :country, :string
    field :city, :string
    field :latitude, :decimal
    field :longitude, :decimal
    field :mystery_value, :string
    timestamps()
  end

  @fields [
    :ip_address,
    :country_code,
    :country,
    :city,
    :latitude,
    :longitude,
    :mystery_value,
    :inserted_at,
    :updated_at
  ]
  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @fields)
    |> validate_required([:ip_address])
  end
end
