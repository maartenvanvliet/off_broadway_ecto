defmodule OffBroadwayEcto.Producer do
  @moduledoc """
  Documentation for `OffBroadwayEcto`.
  """

  use GenStage

  alias Broadway.Producer
  alias Broadway.Message
  alias NimbleOptions.ValidationError

  @behaviour Producer

  @impl true
  def init(opts) do
    receive_interval = opts[:receive_interval]

    {_client, client_opts} =
      get_in(
        opts,
        [:broadway, :producer, :module]
      )

    client = normalize_client(opts[:client]) |> IO.inspect()

    {:producer,
     %{
       demand: 0,
       max_demand: opts[:max_demand],
       receive_timer: nil,
       receive_interval: receive_interval,
       client: client,
       ack_ref: client_opts[:ack_ref]
     }}
  end

  @impl Broadway.Producer
  def prepare_for_start(_module, broadway_opts) do
    {producer_module, client_opts} = broadway_opts[:producer][:module]

    case NimbleOptions.validate(client_opts, OffBroadwayEcto.Options.definition()) do
      {:error, error} ->
        raise ArgumentError, format_error(error)

      {:ok, opts} ->
        ack_ref = broadway_opts[:name]

        :persistent_term.put(ack_ref, %{
          client: opts[:client]
        })

        broadway_opts_with_defaults =
          put_in(
            broadway_opts,
            [:producer, :module],
            {producer_module, [{:ack_ref, ack_ref} | opts]}
          )

        {[], broadway_opts_with_defaults}
    end
  end

  defp format_error(%ValidationError{keys_path: [], message: message}) do
    "invalid configuration given to SQSBroadway.prepare_for_start/2, " <> message
  end

  defp format_error(%ValidationError{keys_path: keys_path, message: message}) do
    "invalid configuration given to SQSBroadway.prepare_for_start/2 for key #{inspect(keys_path)}, " <>
      message
  end

  @impl true
  def handle_demand(incoming_demand, %{demand: demand} = state) do
    handle_receive_messages(%{state | demand: demand + incoming_demand})
  end

  @impl true
  def handle_info(:receive_messages, %{receive_timer: nil} = state) do
    {:noreply, [], state}
  end

  @impl true
  def handle_info(:receive_messages, state) do
    handle_receive_messages(%{state | receive_timer: nil})
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, [], state}
  end

  defp handle_receive_messages(
         %{receive_timer: nil, demand: demand, max_demand: max_demand} = state
       )
       when demand > 0 do
    messages = receive_messages_from_ecto(state, min(max_demand, demand))
    new_demand = demand - length(messages)

    receive_timer =
      case {messages, new_demand} do
        {[], _} -> schedule_receive_messages(state.receive_interval)
        {_, 0} -> nil
        _ -> schedule_receive_messages(0)
      end

    {:noreply, messages, %{state | demand: new_demand, receive_timer: receive_timer}}
  end

  defp handle_receive_messages(state) do
    {:noreply, [], state}
  end

  defp receive_messages_from_ecto(state, total_demand) do
    %{client: {client, opts}} = state
    metadata = %{name: get_in(opts, [:ack_ref]), demand: total_demand}

    :telemetry.span(
      [:off_broadway_ecto, :receive_messages],
      metadata,
      fn ->
        messages =
          client.receive_messages(total_demand, opts)
          |> wrap_received_messages(state.ack_ref)

        {messages, Map.put(metadata, :messages, messages)}
      end
    )
  end

  defp wrap_received_messages(messages, ack_ref) do
    Enum.map(messages, fn message ->
      metadata = %{}
      acknowledger = build_acknowledger(message, ack_ref)
      %Message{data: message, metadata: metadata, acknowledger: acknowledger}
    end)
  end

  defp build_acknowledger(_message, ack_ref) do
    {OffBroadwayEcto.Acknowledger, ack_ref, :ack_data}
  end

  defp schedule_receive_messages(interval) do
    Process.send_after(self(), :receive_messages, interval)
  end

  defp normalize_client({_client, _opts} = client) do
    client
  end

  defp normalize_client(client) when is_atom(client) do
    {client, []}
  end
end
