defmodule PlatformWeb.ScoreChannel do
  @moduledoc """
  Track scores from Elm front-end games (via elm-phoenix-socket).

  Channel joins can use each game's slug so this should be reusable for
  different games that send a `player_score` value.

  The "save_score" message should allow players to both save their score to
  the database and also broadcast it to any other users connected to the
  socket.
  """

  use PlatformWeb, :channel
  use Appsignal.Instrumentation.Decorators

  alias Platform.GamePresence
  alias Platform.Products

  def join("score:" <> game_slug, _payload, socket) do
    game = Products.get_game_by_slug!(game_slug)
    socket = assign(socket, :game_id, game.id)

    send(self(), :after_join)

    {:ok, socket}
  end

  @decorate channel_action()
  def handle_in("save_score", %{"player_score" => player_score}, socket) do
    payload = %{
      player_score: player_score,
      game_id: socket.assigns.game_id,
      player_id: socket.assigns.player_id
    }

    Products.create_gameplay(payload)
    broadcast(socket, "save_score", payload)
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", GamePresence.list(socket))

    {:ok, _} = GamePresence.track(socket, socket.assigns.player_id, %{
      online_at: inspect(System.system_time(:seconds))
    })

    {:noreply, socket}
  end
end
