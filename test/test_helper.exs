Application.ensure_all_started(:postgrex)
Application.ensure_all_started(:ecto)

_ = Ecto.Adapters.Postgres.storage_down(OffBroadwayEcto.Repo.config())
:ok = Ecto.Adapters.Postgres.storage_up(OffBroadwayEcto.Repo.config())
{:ok, _} = OffBroadwayEcto.Repo.start_link()
:ok = Ecto.Migrator.up(OffBroadwayEcto.Repo, 0, OffBroadwayEcto.TestMigration, log: false)

Ecto.Adapters.SQL.Sandbox.mode(OffBroadwayEcto.Repo, {:shared, self()})

ExUnit.start(timeout: 120_000)
