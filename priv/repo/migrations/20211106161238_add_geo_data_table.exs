defmodule Geolocation.Repo.Migrations.AddGeoDataTable do
  use Ecto.Migration

  def change do
    create table("geo_data") do
      add :ip_address, :string
      add :country_code, :string
      add :country, :string
      add :city, :string
      add :latitude, :decimal
      add :longitude, :decimal
      add :mystery_value, :string
      timestamps()
    end
  end
end
