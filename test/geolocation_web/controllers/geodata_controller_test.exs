defmodule GeolocationWeb.GeodataControllerTest do
  use GeolocationWeb.ConnCase
  import Geolocation.Factory

  describe "GET /geodata" do
    test "fails in case of wrong ip", %{conn: conn} do
      conn = get(conn, "/geo_data", ip_address: "a")
      assert json_response(conn, 400) == %{"error" => "Invalid IP"}
    end

    test "gives empty response when ip doesn't exists in database", %{conn: conn} do
      conn = get(conn, "/geo_data", ip_address: "1.1.1.1")
      assert json_response(conn, 200) == %{}
    end

    test "gives successful response when ip address exists", %{conn: conn} do
      insert(:geo_data, %{
        ip_address: "1.1.1.1",
        country_code: "CA",
        country: "England",
        city: "London",
        latitude: "123.0",
        longitude: "57.0",
        mystery_value: "124569"
      })

      conn = get(conn, "/geo_data", ip_address: "1.1.1.1")

      assert json_response(conn, 200) == %{
               "ip_address" => "1.1.1.1",
               "country_code" => "CA",
               "country" => "England",
               "city" => "London",
               "latitude" => "123.0",
               "longitude" => "57.0",
               "mystery_value" => "124569"
             }
    end
  end
end
