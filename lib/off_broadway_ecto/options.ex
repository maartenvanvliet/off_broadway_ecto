defmodule OffBroadwayEcto.Options do
  def definition() do
    [
      receive_interval: [
        type: :non_neg_integer,
        doc: """
        The duration (in milliseconds) for which the producer
        waits before making a request for more messages.
        """,
        default: 5000
      ],
      client: [
        required: true,
        doc: """
        A module that implements the `OffBroadwayEcto.Client`
        behaviour. This module is responsible for fetching and acknowledging the
        messages.
        """
      ],
      demand: [
        doc: """
        Base number of records fetched from the database.
        """,
        default: 10
      ]
    ]
  end
end
