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
    work_minutes = 30
    work_seconds = work_minutes * 60

    work_timer_opts = [
      timer_name: :work_timer,
      font_size: 80,
      on_start: fn ->
        set_pomodoro_slack_status(work_minutes)
      end,
      on_finish: fn ->
        Process.send(self, {:start_rest_timer, opts[:viewport]}, [])
      end,
      timer: [
        direction: :count_down,
        initial_seconds: work_seconds,
        final_seconds: 0
      ]
    ]

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> Timer.Components.CountdownClock.add_to_graph(work_timer_opts, id: :work_timer, t: t)
      |> Scenic.Components.button("Reset", id: :btn_reset, t: {10, 10}, button_font_size: 30)
      |> Launcher.HiddenHomeButton.add_to_graph(on_switch: &clear_pomodoro_slack_status/0)

    schedule_refresh()

    {:ok, %State{graph: graph}, push: graph}
  end

  @impl Scenic.Scene
  def handle_input(_event, _context, state) do
    # Logger.info("Received event: #{inspect(event)}")

    {:noreply, state}
  end

  @impl Scenic.Scene
  def handle_info(:refresh, state) do
    schedule_refresh()
    {:noreply, state, push: state.graph}
  end

  def handle_info({:start_rest_timer, viewport}, state) do
    %State{graph: graph} = state
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(viewport)

    rest_timer_opts = [
      timer_name: :rest_timer,
      font_size: 35,
      start_immediately: true,
      timer: [
        direction: :count_up,
        initial_seconds: 0,
        final_seconds: 60 * 10
      ]
    ]

    graph =
      graph
      |> Timer.Components.CountdownClock.add_to_graph(rest_timer_opts,
        id: :rest_timer,
        t: {width / 2, height / 2 + height / 4}
      )

    state = %State{state | graph: graph}

    clear_pomodoro_slack_status()

    {:noreply, state, push: graph}
  end

  def handle_info(_msg, state) do
    # Logger.info("Received info message: #{inspect msg}")
    {:noreply, state}
  end

  @impl Scenic.Scene
  def filter_event({:click, :btn_reset}, _from, state) do
    reset_scene()
    {:halt, state}
  end

  defp reset_scene do
    clear_pomodoro_slack_status()
    # A lazy(?) way to reset the scene
    Process.exit(self(), :kill)
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_rate)
  end

  defp set_pomodoro_slack_status(minutes) do
    Task.start(fn ->
      Timer.SlackControls.enable_dnd(minutes)
      Timer.SlackControls.set_status("mid-pomodoro", ":tomato:", duration_minutes: minutes)
    end)
  end

  defp clear_pomodoro_slack_status do
    Task.start(fn ->
      Timer.SlackControls.disable_dnd()
      Timer.SlackControls.clear_status()
    end)
  end
end
