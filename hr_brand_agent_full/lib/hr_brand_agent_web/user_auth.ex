defmodule HrBrandAgentWeb.UserAuth do
  @moduledoc """
  Authentication module for LiveView.
  """
  import Phoenix.Component
  import Phoenix.LiveView

  alias HrBrandAgent.Accounts

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(session, socket)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: "/dashboard")}
    else
      {:cont, socket}
    end
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(session, socket)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: "/users/log_in")

      {:halt, socket}
    end
  end

  defp mount_current_user(session, socket) do
    case session do
      %{"user_token" => user_token} ->
        assign_new(socket, :current_user, fn ->
          Accounts.get_user_by_session_token(user_token)
        end)

      %{} ->
        assign_new(socket, :current_user, fn -> nil end)
    end
  end
end
