defmodule PomodoroUi.Scene.Main do
  use Scenic.Scene
  require Logger

  alias Pomodoro.PomodoroTimer
  alias Scenic.Graph
  alias Scenic.ViewPort

  @refresh_rate round(1_000 / 30)

  defmodule State do
    defstruct [:graph, :pomodoro_timer_pid]
  end

  @impl Scenic.Scene
  def init(_, scenic_opts) do
    viewport = scenic_opts[:viewport]
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(viewport)

    t = {width / 2, height / 2}

    # instantiate a timer
    {:ok, pomodoro_timer_pid} = PomodoroTimer.start_link([])
    pomodoro_timer = PomodoroTimer.get_timer()

    # insantiate a timer component
    graph =
      Graph.build(font: :roboto)
      |> PomodoroUi.TimerComponent.add_to_graph([pomodoro_timer: pomodoro_timer], t: t)
      |> PomodoroUi.RestButtonComponent.add_to_graph([pomodoro_timer: pomodoro_timer], t: t)
      |> Scenic.Components.button("Reset", id: :btn_reset, t: {10, 10}, button_font_size: 40)
      |> PomodoroUi.TimeControlsComponent.add_to_graph(
        [pomodoro_timer: pomodoro_timer, viewport: viewport],
        []
      )
      |> Scenic.Components.toggle(true, id: :toggle_slack, t: {10, 163})
      |> Scenic.Primitives.text("Update Slack", t: {65, 170})
      |> Launcher.HiddenHomeButton.add_to_graph(on_switch: fn -> send(self(), :reset) end)

    schedule_refresh()

    {:ok, %State{graph: graph, pomodoro_timer_pid: pomodoro_timer_pid}, push: graph}
  end

  @impl Scenic.Scene
  def handle_info(:refresh, state) do
    %State{graph: graph} = state
    schedule_refresh()
    {:noreply, state, push: graph}
  end

  def handle_info(:reset, state) do
    reset_timer(state)
    {:noreply, state}
  end

  @impl Scenic.Scene
  def filter_event({:click, :btn_reset}, _from, state) do
    reset_timer(state)
    {:halt, state}
  end

  def filter_event({:click, :btn_rest}, _from, state) do
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    :ok = PomodoroTimer.rest(pomodoro_timer_pid)
    {:halt, state}
  end

  def filter_event({:click, :btn_add_time}, _from, state) do
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    :ok = PomodoroTimer.add_time(pomodoro_timer_pid, 5 * 60)
    {:halt, state}
  end

  def filter_event({:click, :btn_subtract_time}, _from, state) do
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    :ok = PomodoroTimer.subtract_time(pomodoro_timer_pid, 5 * 60)
    {:halt, state}
  end

  def filter_event({:value_changed, :toggle_slack, value}, _from, state) do
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    PomodoroTimer.set_slack_enabled_status(pomodoro_timer_pid, value)
    {:halt, state}
  end

  def filter_event(event, _from, state) do
    Logger.warn("Unhandled event: #{inspect(event)}")
    {:halt, state}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_rate)
  end

  defp reset_timer(state) do
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    :ok = PomodoroTimer.reset(pomodoro_timer_pid)
  end
end
