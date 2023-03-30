defmodule OffBroadwayEcto.Client do
  @callback receive_messages(demand :: integer, opts :: Keyword.t()) :: term
  @callback handle_failed(schemas :: list(term), client_opts :: Keyword.t()) :: :ok
  @callback handle_successful(schemas :: list(term), client_opts :: Keyword.t()) :: :ok
end
