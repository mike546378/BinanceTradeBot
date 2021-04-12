defmodule CmcscraperWeb.PageController do
  use CmcscraperWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
