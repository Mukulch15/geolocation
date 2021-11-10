defmodule GeolocationWeb.GeodataController do
  use GeolocationWeb, :controller

  def show(conn, params) do
    case Geolocation.get_deo_data(params["ip_address"]) do
      :bad_request ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid IP"})

      :internal_server_error ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Some error occurred"})

      data ->
        json(conn, data)
    end
  end
end
