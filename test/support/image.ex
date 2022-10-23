defmodule OffBroadwayEcto.Image do
  @moduledoc false
  use Ecto.Schema

  schema "images" do
    field(:state, Ecto.Enum, values: [:queue, :pending, :finished, :errored])
    field(:title, :string)
    timestamps()
  end
end
