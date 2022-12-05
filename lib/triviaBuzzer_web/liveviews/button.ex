defmodule TriviaBuzzerWeb.ButtonLive do
  # In Phoenix v1.6+ apps, the line below should be: use MyAppWeb, :live_view
  use TriviaBuzzerWeb, :live_view

  alias Phoenix.PubSub

  def render(assigns) do
    ~H"""
    Clicked: <%= @clicked %>
    <button disabled={@clicked} phx-click="click">+</button>
    """
  end

  def mount(_params, _, socket) do
    PubSub.subscribe(TriviaBuzzer.PubSub, "room:123")
    clicked = false
    {:ok, assign(socket, :clicked, clicked)}
  end

  def handle_event("click", _value, socket) do
    # IO.puts(socket.assigns.clicked)
    # {:ok, new_temp} = socket.assigns.clicked
    PubSub.broadcast_from(TriviaBuzzer.PubSub, self(), "room:123", {:clicked, %{id: 123, name: "Shane"}})
    {:noreply, assign(socket, :clicked, true)}
  end

  def handle_info({:clicked, %{id: id, name: name}}, socket) do
    IO.puts("User: #{name}" )
    {:noreply, assign(socket, :clicked, true)}
  end
end
