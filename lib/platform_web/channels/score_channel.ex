defmodule PlatformWeb.ScoreChannel do
  use PlatformWeb, :channel

  alias Platform.Accounts
  alias Platform.Products

  def join("score:" <> game_slug, payload, socket) do
    if authorized?(payload) do
      game = Products.get_game_by_slug!(game_slug)
      socket = assign(socket, :game_id, game.id)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("save_score", %{"player_score" => player_score} = payload, socket) do
    payload = %{
      player_score: player_score,
      game_id: socket.assigns.game_id,
      player_id: socket.assigns.player_id
    }

    Products.create_gameplay(payload)
    broadcast(socket, "save_score", payload)
    {:noreply, socket}
  end

  defp authorized?(_payload) do
    true
  end
end
