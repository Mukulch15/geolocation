defmodule GeolocationWeb.PageController do
  use GeolocationWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
