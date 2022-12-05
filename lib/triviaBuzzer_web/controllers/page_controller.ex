defmodule TriviaBuzzerWeb.PageController do
  use TriviaBuzzerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
