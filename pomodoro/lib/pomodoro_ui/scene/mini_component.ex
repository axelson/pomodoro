defmodule PomodoroUi.Scene.MiniComponent do
  @moduledoc """
  An embeddable version of the main scene
  """

  use Scenic.Component
  require Logger
  require ScenicContrib.Utils

  alias Pomodoro.PomodoroTimer
  alias Scenic.Graph

  @refresh_rate round(1_000 / 30)

  defmodule State do
    defstruct [:graph, :pomodoro_timer_pid]
  end

  @impl Scenic.Component
  def validate(data), do: {:ok, data}

  @impl Scenic.Scene
  def init(scene, opts, _scenic_opts) do
    pomodoro_timer_pid =
      Keyword.get_lazy(opts, :pomodoro_timer_pid, fn ->
        {:ok, pomodoro_timer_pid} = PomodoroTimer.start_link([])
        pomodoro_timer_pid
      end)

    pomodoro_timer = PomodoroTimer.get_timer(pomodoro_timer_pid)

    component_width = 110
    {t_x, t_y} = Keyword.get(opts, :t)
    time_display_t = {t_x, t_y + 145}

    graph =
      Graph.build(font: :roboto)
      |> PomodoroUi.TimerComponent.add_to_graph([pomodoro_timer: pomodoro_timer],
        t: time_display_t
      )
      |> ScenicUtils.ScenicRendererBehaviour.add_to_graph(
        mod: PomodoroUi.RestButtonComponent,
      opts: [
        pomodoro_timer: pomodoro_timer
      ]
      )
      |> ScenicContrib.IconComponent.add_to_graph(
        [
          icon: {:pomodoro, "images/timer_reset_rest.png"},
          on_press_icon: {:pomodoro, "images/timer_reset_select.png"},
          width: 46,
          height: 62,
          on_click: &on_reset/0
        ],
        id: :btn_reset,
        t: {463, 367}
      )
      |> ScenicUtils.ScenicRendererBehaviour.add_to_graph(
        [
          mod: PomodoroUi.TimeControlsComponent,
          opts: [
            pomodoro_timer: pomodoro_timer,
            x1: t_x - component_width / 2 - 30,
            x2: t_x + component_width / 2 - 30,
            y: t_y + 45
          ]
        ],
        []
      )

    schedule_refresh()
    state = %State{graph: graph, pomodoro_timer_pid: pomodoro_timer_pid}

    scene =
      scene
      |> assign(:state, state)
      |> push_graph(graph)

    {:ok, scene}
  end

  @impl GenServer
  def handle_info(:refresh, scene) do
    state = scene.assigns.state
    %State{graph: graph} = state
    schedule_refresh()
    scene = push_graph(scene, graph)
    {:noreply, scene}
  end

  def handle_info(:reset, scene) do
    reset_timer(scene.assigns.state)
    {:noreply, scene}
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

  def handle_event(event, _from, scene) do
    Logger.warn("Unhandled event: #{inspect(event)}")
    {:halt, scene}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_rate)
  end

  defp reset_timer(state) do
    %State{pomodoro_timer_pid: pomodoro_timer_pid} = state
    :ok = PomodoroTimer.reset(pomodoro_timer_pid)
  end

  defp on_reset do
    Process.sleep(100)
    :ok = PomodoroTimer.reset()
  end
end
