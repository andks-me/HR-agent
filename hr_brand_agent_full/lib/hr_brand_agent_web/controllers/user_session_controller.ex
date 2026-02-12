defmodule HrBrandAgentWeb.UserSessionController do
  use HrBrandAgentWeb, :controller

  alias HrBrandAgent.Accounts

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> put_session(:user_token, generate_user_token(user))
        |> redirect(to: ~p"/dashboard")
      
      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> delete_session(:user_token)
    |> redirect(to: ~p"/")
  end

  defp generate_user_token(user) do
    # Simple token generation - in production use a proper token library
    :crypto.strong_rand_bytes(32) |> Base.encode64()
  end
end
