defmodule Timer.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  @text_size 24
  @refresh_rate round(1_000 / 30)

  defmodule State do
    defstruct [:graph]
  end

  @impl Scenic.Scene
  def init(_, opts) do
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    t = {width / 2, height / 2}
    self = self()

    work_timer_opts = [
      timer_name: :work_timer,
      font_size: 80,
      on_finish: fn ->
        Process.send(:rest_timer_component, {:start_ticking}, [])
      end,
      timer: [
        direction: :count_down,
        initial_seconds: 60 * 25,
        final_seconds: 0
      ]
    ]

    rest_timer_opts = [
      timer_name: :rest_timer,
      font_size: 35,
      # FIXME: This feels very hacky
      on_init: fn ->
        Process.register(self(), :rest_timer_component)
      end,
      timer: [
        direction: :count_up,
        initial_seconds: 0,
        final_seconds: 60 * 10
      ]
    ]

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> Timer.Components.CountdownClock.add_to_graph(work_timer_opts, id: :work_timer, t: t)
      |> Timer.Components.CountdownClock.add_to_graph(rest_timer_opts,
        id: :rest_timer,
        t: {width / 2, height / 2 + height / 4}
      )
      |> Launcher.HiddenHomeButton.add_to_graph([])

    schedule_refresh()

    {:ok, %State{graph: graph}, push: graph}
  end

  @impl Scenic.Scene
  def handle_input(event, _context, state) do
    # Logger.info("Received event: #{inspect(event)}")

    {:noreply, state}
  end

  @impl Scenic.Scene
  def handle_info(:refresh, state) do
    schedule_refresh()
    {:noreply, state, push: state.graph}
  end

  def handle_info(msg, state) do
    # Logger.info("Received info message: #{inspect msg}")
    {:noreply, state}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_rate)
  end
end
