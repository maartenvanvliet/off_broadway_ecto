defmodule OffBroadwayEcto.Acknowledger do
  @behaviour Broadway.Acknowledger

  @impl true
  def ack(ack_ref, successful, failed) do
    opts = :persistent_term.get(ack_ref)

    :ok = opts[:client].handle_failed(failed)

    :ok = opts[:client].handle_successful(successful)
  end
end
