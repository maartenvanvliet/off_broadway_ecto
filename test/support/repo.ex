defmodule OffBroadwayEcto.Repo do
  use Ecto.Repo,
    otp_app: :off_broadway_ecto,
    adapter: Ecto.Adapters.Postgres

  def init(_type, config) do
    test_config = [
      pool: Ecto.Adapters.SQL.Sandbox,
      username: "postgres",
      password: "postgres",
      database: "offbroadway_ecto_test",
      hostname: System.get_env("DB_HOST", "localhost"),
      port: System.get_env("DB_PORT", "5432")
    ]

    {:ok, Keyword.merge(config, test_config)}
  end
end
