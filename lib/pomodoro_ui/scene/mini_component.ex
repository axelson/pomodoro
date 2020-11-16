defmodule PomodoroUi.Scene.MiniComponent do
  @moduledoc """
  An embeddable version of the main scene
  """

  use Scenic.Component
  require Logger

  alias Pomodoro.PomodoroTimer
  alias Scenic.Graph
  alias Scenic.ViewPort

  @refresh_rate round(1_000 / 30)

  defmodule State do
    defstruct [:graph, :pomodoro_timer_pid]
  end

  @impl Scenic.Component
  def verify(data), do: {:ok, data}

  def init(opts, scenic_opts) do
    viewport = scenic_opts[:viewport]
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(viewport)

    component_width = 110
    {t_x, t_y} = t = Keyword.get(opts, :t)
    reset_btn_t = {t_x - component_width + 25, t_y}
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
