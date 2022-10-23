defmodule OffBroadwayEcto.TestMigration do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:images) do
      add(:state, :text)
      add(:title, :text)
      timestamps()
    end
  end
end
