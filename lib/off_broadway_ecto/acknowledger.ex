defmodule OffBroadwayEcto.Acknowledger do
  @behaviour Broadway.Acknowledger

  @impl true
  def ack(ack_ref, successful, failed) do
    opts = :persistent_term.get(ack_ref)
    {client, opts} = normalize_client(opts[:client])

    if function_exported?(client, :handle_failed, 2) do
      :ok = client.handle_failed(failed, opts)
    else
      :ok = client.handle_failed(failed)
    end

    if function_exported?(client, :handle_successful, 2) do
      :ok = client.handle_successful(successful, opts)
    else
      :ok = client.handle_successful(successful)
    end
  end

  defp normalize_client({_client, _opts} = client) do
    client
  end

  defp normalize_client(client) when is_atom(client) do
    {client, []}
  end
end
