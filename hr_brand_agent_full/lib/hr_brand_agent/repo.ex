defmodule HrBrandAgent.Repo do
  use Ecto.Repo,
    otp_app: :hr_brand_agent,
    adapter: Ecto.Adapters.SQLite3

  @doc """
  Convenience function to check if using SQLite.
  """
  def using_sqlite? do
    Application.get_env(:hr_brand_agent, __MODULE__)[:adapter] == Ecto.Adapters.SQLite3
  end
end
