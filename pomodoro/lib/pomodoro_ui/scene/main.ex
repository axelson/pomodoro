defmodule PomodoroUi.Scene.Main do
  use Scenic.Scene
  require Logger

  alias Pomodoro.PomodoroTimer
  alias Scenic.Graph

  @refresh_rate round(1_000 / 30)

  defmodule State do
    defstruct [:graph, :pomodoro_timer_pid]
  end

  @impl Scenic.Scene
  def init(scene, opts, _scenic_opts) do
    %Scenic.ViewPort{size: {width, height}} = scene.viewport

    pomodoro_timer_pid =
      Keyword.get_lazy(opts, :pomodoro_timer_pid, fn ->
        {:ok, pomodoro_timer_pid} = PomodoroTimer.start_link([])
        pomodoro_timer_pid
      end)

    pomodoro_timer = PomodoroTimer.get_timer(pomodoro_timer_pid)

    t = {width / 2, height / 2}

    graph =
      Graph.build(font: :roboto)
      |> PomodoroUi.TimerComponent.add_to_graph([pomodoro_timer: pomodoro_timer], t: t)
      |> Scenic.Components.button("Reset", id: :btn_reset, t: {10, 10}, button_font_size: 40)
      |> ScenicUtils.ScenicRendererBehaviour.add_to_graph(
        [
          mod: PomodoroUi.TimeControlsComponent,
          opts: [pomodoro_timer: pomodoro_timer, width: width, height: height]
        ],
        []
      )
      |> maybe_add_update_slack_controls(Pomodoro.slack_controls_enabled?())
      |> Launcher.HiddenHomeButton.add_to_graph(on_switch: fn -> send(self(), :reset) end)

    schedule_refresh()

    state = %State{graph: graph, pomodoro_timer_pid: pomodoro_timer_pid}

    scene =
      scene
      |> assign(:state, state)
      |> push_graph(graph)

    {:ok, scene}
  end

  defp maybe_add_update_slack_controls(graph, false), do: graph

  defp maybe_add_update_slack_controls(graph, true) do
    graph
    |> Scenic.Primitives.text("Update Slack", t: {65, 170})
    |> Scenic.Components.toggle(true, id: :toggle_slack, t: {10, 163})
  end

  @impl GenServer
  def handle_info(:refresh, scene) do
    state = scene.assigns.state
    %State{graph: graph} = state
    schedule_refresh()

    # NOTE: This is not working, it does not cause the image to be redisplayed (at least on Arch Linux)
    # This is probably: https://github.com/boydm/scenic_driver_glfw/issues/15
    scene = push_graph(scene, graph)

    {:noreply, scene}
  end

  def handle_info(:reset, scene) do
    reset_timer(scene.assigns.state)
    {:noreply, scene}
  end

  def handle_info(msg, scene) do
    Logger.warn("Unhandled handle_info: #{inspect(msg)}")
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_input(event, _hit_id, scene) do
    Logger.warn("Unhandled input: #{inspect(event)}")
    {:halt, scene}
  end

  @impl Scenic.Scene
  def handle_event({:click, :btn_reset}, _from, scene) do
    reset_timer(scene.assigns.state)
    {:halt, scene}
  end

  def handle_event({:click, :btn_rest}, _from, scene) do
    state = scene.assigns.state
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    :ok = PomodoroTimer.rest(pomodoro_timer_pid)
    {:halt, scene}
  end

  def handle_event({:click, :btn_add_time}, _from, scene) do
    state = scene.assigns.state
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    :ok = PomodoroTimer.add_time(pomodoro_timer_pid, 5 * 60)
    {:halt, scene}
  end

  def handle_event({:click, :btn_subtract_time}, _from, scene) do
    state = scene.assigns.state
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    :ok = PomodoroTimer.subtract_time(pomodoro_timer_pid, 5 * 60)
    {:halt, scene}
  end

  def handle_event({:value_changed, :toggle_slack, value}, _from, scene) do
    state = scene.assigns.state
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    PomodoroTimer.set_slack_enabled_status(pomodoro_timer_pid, value)
    {:halt, scene}
  end

  def handle_event(event, _from, scene) do
    Logger.warn("Unhandled event: #{inspect(event)}")
    {:noreply, scene}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_rate)
  end

  defp reset_timer(state) do
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    :ok = PomodoroTimer.reset(pomodoro_timer_pid)
  end
end
