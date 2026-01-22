defmodule TriviaBuzzerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :trivia_buzzer

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_triviaBuzzer_key",
    signing_salt: "Mqs8EwNl"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :trivia_buzzer,
    gzip: false,
    only: ~w(assets fonts images favicon.ico favicon.svg robots.txt sitemap.xml og-image.svg)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :trivia_buzzer
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  
  # Add Content Security Policy that allows Cloudflare Web Analytics
  plug :put_content_security_policy
  
  plug Plug.Session, @session_options
  plug TriviaBuzzerWeb.Router
end

defp put_content_security_policy(conn, _opts) do
  csp = [
    "default-src 'self'",
    # Allow Cloudflare Web Analytics scripts
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://static.cloudflareinsights.com",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src 'self' https://fonts.gstatic.com",
    "img-src 'self' data: https:",
    # Allow connections to Cloudflare analytics endpoints
    "connect-src 'self' wss: ws: https://cloudflareinsights.com https://*.cloudflareinsights.com",
    "frame-ancestors 'none'"
  ] |> Enum.join("; ")
  
  Plug.Conn.put_resp_header(conn, "content-security-policy", csp)
end
