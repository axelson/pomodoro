defmodule PomodoroUi.Scene.MiniComponent do
  @moduledoc """
  An embeddable version of the main scene
  """

  use Scenic.Component
  require Logger

  alias Pomodoro.PomodoroTimer
  alias Scenic.Graph

  @refresh_rate round(1_000 / 30)

  defmodule State do
    defstruct [:graph, :pomodoro_timer_pid]
  end

  @impl Scenic.Component
  def validate(data), do: {:ok, data}

  @impl Scenic.Scene
  def init(scene, opts, scenic_opts) do
    viewport = scenic_opts[:viewport]

    component_width = 110
    {t_x, t_y} = Keyword.get(opts, :t)
    reset_btn_t = {t_x - component_width + 10, t_y}
    time_display_t = {t_x, t_y + 145}

    pomodoro_timer_pid = Keyword.get(opts, :pomodoro_timer_pid)

    {pomodoro_timer, pomodoro_timer_pid} =
      if pomodoro_timer_pid do
        pomodoro_timer = Keyword.fetch!(opts, :pomodoro_timer)
        {pomodoro_timer, pomodoro_timer_pid}
      else
        timer_opts = []
        {:ok, pomodoro_timer_pid} = PomodoroTimer.start_link(timer_opts)
        pomodoro_timer = PomodoroTimer.get_timer()
        {pomodoro_timer, pomodoro_timer_pid}
      end

    graph =
      Graph.build(font: :roboto)
      |> PomodoroUi.TimerComponent.add_to_graph([pomodoro_timer: pomodoro_timer],
        t: time_display_t
      )
      |> PomodoroUi.RestButtonComponent.add_to_graph([pomodoro_timer: pomodoro_timer],
        t: time_display_t
      )
      |> Scenic.Components.button("Reset", id: :btn_reset, t: reset_btn_t, button_font_size: 20)
      |> ScenicUtils.ScenicRendererBehaviour.add_to_graph(
        [
          mod: PomodoroUi.TimeControlsComponent,
          opts: [
            pomodoro_timer: pomodoro_timer,
            viewport: viewport,
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
end
