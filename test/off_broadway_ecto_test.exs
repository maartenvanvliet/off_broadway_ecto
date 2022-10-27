defmodule OffBroadwayEctoTest do
  use ExUnit.Case
  import Ecto.Query
  alias OffBroadwayEcto.Repo

  test "producer" do
    {:ok, pid} = start_broadway()
    # assert OffBroadwayEcto.hello() == :world
    {:ok, image1} = create(title: "a title")
    {:ok, image2} = create()
    assert_receive {:message_handled, %OffBroadwayEcto.Image{id: _, state: :pending}, %{}}

    Process.sleep(100)
    image1 = OffBroadwayEcto.Image |> where(id: ^image1.id) |> Repo.one()
    assert image1.state == :finished
    image2 = OffBroadwayEcto.Image |> where(id: ^image2.id) |> Repo.one()
    assert image2.state == :errored
    stop_broadway(pid)
  end

  def create(attrs \\ []) do
    struct!(OffBroadwayEcto.Image, attrs |> Keyword.merge(state: :queue)) |> Repo.insert()
  end

  defmodule TestClient do
    @behaviour OffBroadwayEcto.Client
    import Ecto.Query

    defp available_jobs(demand) do
      OffBroadwayEcto.Image
      |> where(state: :queue)
      |> lock("FOR UPDATE SKIP LOCKED")
      |> limit(^demand)
    end

    def receive_messages(demand, opts) do
      schema = OffBroadwayEcto.Image

      {count, jobs} =
        OffBroadwayEcto.Image
        |> with_cte("available_jobs", as: ^available_jobs(demand))
        |> join(:inner, [job], a in "available_jobs", on: job.id == a.id)
        |> select([job], job)
        |> OffBroadwayEcto.Repo.update_all(set: [state: :pending])

      jobs
    end

    def handle_failed(schemas) do
      ids =
        schemas
        |> Enum.map(& &1.data.id)

      if ids != [] do
        OffBroadwayEcto.Image
        |> where([i], i.id in ^ids)
        |> OffBroadwayEcto.Repo.update_all(set: [state: :errored])
      end

      :ok
    end

    def handle_successful(schemas) do
      ids =
        schemas
        |> Enum.map(& &1.data.id)

      if ids != [] do
        OffBroadwayEcto.Image
        |> where([i], i.id in ^ids)
        |> OffBroadwayEcto.Repo.update_all(set: [state: :finished])
      end

      :ok
    end
  end

  defmodule Forwarder do
    use Broadway

    def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

    def init(opts) do
      {:ok, opts}
    end

    def handle_message(_, message, %{test_pid: test_pid}) do
      send(test_pid, {:message_handled, message.data, message.metadata})

      if message.data.title do
        message
      else
        Broadway.Message.failed(message, "No title")
      end
    end

    def handle_batch(_, messages, _, %{test_pid: test_pid}) do
      send(test_pid, {:batch_handled, messages})
      messages
    end
  end

  defp start_broadway(broadway_name \\ new_unique_name(), opts \\ []) do
    Broadway.start_link(
      Forwarder,
      build_broadway_opts(broadway_name, opts,
        client: {TestClient, a: 1},
        # receive_interval: 1000,
        test_pid: self()
      )
    )
  end

  defp build_broadway_opts(broadway_name, opts, producer_opts) do
    producer_opts = Keyword.merge(producer_opts, opts) |> Keyword.drop([:test_pid])

    [
      name: broadway_name,
      context: %{test_pid: self()},
      producer: [
        module: {OffBroadwayEcto.Producer, producer_opts},
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 1]
      ],
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 50,
          concurrency: 1
        ]
      ]
    ]
  end

  defp new_unique_name() do
    :"Broadway#{System.unique_integer([:positive, :monotonic])}"
  end

  defp stop_broadway(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :normal)

    receive do
      {:DOWN, ^ref, _, _, _} -> :ok
    end
  end
end
