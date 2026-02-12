defmodule HrBrandAgentWeb.UserSessionController do
  use HrBrandAgentWeb, :controller

  alias HrBrandAgent.Accounts
  alias HrBrandAgent.Accounts.User
  alias HrBrandAgent.Accounts.UserToken
  alias HrBrandAgentWeb.UserAuth

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, %User{} = user} ->
        {:ok, token} = Accounts.create_user_session_token(user)

        conn
        |> put_flash(:info, "Welcome back!")
        |> put_session(:user_token, token)
        |> redirect(to: "/dashboard")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> redirect(to: "/users/log_in")
    end
  end

  def delete(conn, _params) do
    if token = get_session(conn, :user_token) do
      Accounts.delete_user_session_token(token)
    end

    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: "/")
  end
end

