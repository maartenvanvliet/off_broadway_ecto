defmodule OffBroadwayEcto.Acknowledger do
  @behaviour Broadway.Acknowledger

  @impl true
  def ack(ack_ref, successful, failed) do
    opts = :persistent_term.get(ack_ref)
    {client, _opts} = normalize_client(opts[:client])

    :ok = client.handle_failed(failed)

    :ok = client.handle_successful(successful)
  end

  defp normalize_client({_client, _opts} = client) do
    client
  end

  defp normalize_client(client) when is_atom(client) do
    {client, []}
  end
end
