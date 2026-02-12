defmodule HrBrandAgentWeb.PageController do
  use HrBrandAgentWeb, :controller

  def home(conn, _params) do
    # If user is logged in, redirect to dashboard
    if conn.assigns[:current_user] do
      redirect(conn, to: "/dashboard")
    else
      # Show landing page
      render(conn, :home, layout: false)
    end
  end
end
