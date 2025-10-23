defmodule TriviaBuzzerWeb.PageController do
  use TriviaBuzzerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def robots(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> text(File.read!("priv/static/robots.txt"))
  end

  def sitemap(conn, _params) do
    conn
    |> put_resp_content_type("application/xml")
    |> text(File.read!("priv/static/sitemap.xml"))
  end
end
