defmodule ControlWeb.PageControllerTest do
  use ControlWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "janky home control"
  end
end
