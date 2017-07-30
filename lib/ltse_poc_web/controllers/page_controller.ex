defmodule LtsePocWeb.PageController do
  use LtsePocWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
