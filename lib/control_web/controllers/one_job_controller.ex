defmodule ControlWeb.OneJobController do
  use ControlWeb, :controller

  def index(conn, _params) do
    render(conn, "one_job/index.html")
  end
end
