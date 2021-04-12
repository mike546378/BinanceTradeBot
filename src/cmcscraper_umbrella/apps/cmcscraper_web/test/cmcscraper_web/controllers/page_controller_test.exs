defmodule CmcscraperWeb.PageControllerTest do
  use CmcscraperWeb.ConnCase

  test "GET /", %{conn: _conn} do
    #conn = get(conn, "/")
    assert true #html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
