defmodule Pay.PageController do
  use Pay.Web, :controller
  require Logger

  def index(conn, _params) do
    render conn, "index.html"
  end


end
